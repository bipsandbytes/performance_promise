require 'active_support/time'
require 'logger'
require './lib/performance_promise.rb'
require './lib/performance_promise/decorators.rb'


RSpec.describe 'PerformancePromise' do
  context '.start' do
    context 'when not enabled' do
      before(:each) do
        PerformancePromise.configure do |config|
          config.enable = false
        end
      end

      it 'does not subscribe to any events' do
        expect(ActiveSupport::Notifications).not_to receive(:subscribe)
        PerformancePromise.start
      end
    end

    context 'when enabled' do
      before(:each) do
        PerformancePromise.configure do |config|
          config.enable = true
        end
      end

      context 'when in production' do
        before(:each) do
          expect(Rails).to receive(:env).and_return('production')
        end

        it 'does not subscribe to any events' do
          expect(ActiveSupport::Notifications).not_to receive(:subscribe)
          PerformancePromise.start
        end
      end

      context 'when in development' do
        it 'subscribe to all events' do
          expect(ActiveSupport::Notifications).to receive(:subscribe).with('sql.active_record')
          expect(ActiveSupport::Notifications).to receive(:subscribe).with('start_processing.action_controller')
          expect(ActiveSupport::Notifications).to receive(:subscribe).with('process_action.action_controller')
          PerformancePromise.start
        end
      end
    end
  end

  context 'after it is started' do
    before(:all) do
      PerformancePromise.configure do |config|
        config.enable = true
      end
      PerformancePromise.start
    end

    it 'records the statement when a SQL statement is executed' do
      expect(SQLRecorder.instance).to receive(:record)
      ActiveSupport::Notifications.instrument('sql.active_record')
    end

    it 'flushes the Recorder when an action loads' do
      expect(SQLRecorder.instance).to receive(:flush)
      ActiveSupport::Notifications.instrument('start_processing.action_controller')
    end

    context 'when the action completes' do
      context 'when the method is tagged' do
        before(:each) do
          PerformancePromise.promises['ActionController#index'] = {
            :makes => 1.queries,
          }
        end
        it 'validates the promise when the method is tagged' do
          expect(PerformancePromise).to receive(:validate_promise)
          ActiveSupport::Notifications.instrument(
            'process_action.action_controller', {
              :controller => :ActionController,
              :action => :index,
            }
          )
        end
      end

      context 'when the method is untagged' do
        before(:each) do
          PerformancePromise.promises['ActionController#index'] = nil
        end

        it 'validates the promise if Speedy is enabled by default' do
          PerformancePromise.configure do |config|
            config.untagged_methods_are_speedy = true
          end
          expect(PerformancePromise).to receive(:validate_promise)
          expect(PerformancePromise.configuration.logger).to receive(:warn).with('No promises made. Assuming Speedy')
          ActiveSupport::Notifications.instrument(
            'process_action.action_controller', {
              :controller => :ActionController,
              :action => :index,
            }
          )
        end

        it 'does not validate promise if Speedy is not enabled by default' do
          PerformancePromise.configure do |config|
            config.untagged_methods_are_speedy = false
          end
          expect(PerformancePromise).not_to receive(:validate_promise)
          ActiveSupport::Notifications.instrument(
            'process_action.action_controller', {
              :controller => :ActionController,
              :action => :index,
            }
          )
        end
      end
    end
  end

  context '.validate_promise' do
    before(:each) do
      PerformancePromise.configure do |config|
        config.enable = true
        config.validations = []
      end
      PerformancePromise.start
    end

    it 'passes promises if all options are disabled' do
      expect(PerformanceValidations).not_to receive(:report_failed_makes)
      expect(PerformanceValidations).not_to receive(:report_failed_takes)
      expect(PerformanceValidations).to receive(:report_promise_passed)
      PerformancePromise.validate_promise('ActionController#index', [], 1, {})
    end

    context 'when asked to validate number of queries' do
      before(:each) do
        PerformancePromise.configure do |config|
          config.validations = [
            :makes,
          ]
        end
      end

      it 'does not do anything if no actual promise is made on #queries' do
        expect(PerformanceValidations).not_to receive(:report_failed_makes)
        expect(PerformanceValidations).to receive(:report_promise_passed)
        PerformancePromise.validate_promise('ActionController#index', [], 1, {})
      end

      context 'when an actual promise is made' do
        it 'reports a failure when a promise fails' do
          options = {
            :makes => 0.queries,
          }
          queries = [
            'SELECT * from articles',
          ]
          expect(PerformanceValidations).to receive(:report_failed_makes).and_return(['', []])
          expect {
            PerformancePromise.validate_promise('ActionController#index', queries, 1, options)
          }.to raise_error(PerformancePromise::BrokenPromise)
        end

        it 'reports a success when a promise passes' do
          options = {
            :makes => 1.query,
          }
          queries = [
            'SELECT * from articles',
          ]
          expect(PerformanceValidations).not_to receive(:report_failed_makes)
          expect(PerformanceValidations).to receive(:report_promise_passed)
          PerformancePromise.validate_promise('ActionController#index', queries, 1, options)
        end

        it 'does not fail if an action is explicitly skipped' do
          options = {
            :makes => 0.queries,
            :skip => true,
          }
          queries = [
            'SELECT * from articles',
          ]
          expect(PerformanceValidations).not_to receive(:report_failed_makes)
          PerformancePromise.validate_promise('ActionController#index', queries, 1, options)
        end
      end
    end

    context 'when asked to validate time taken for render' do
      before(:each) do
        PerformancePromise.configure do |config|
          config.validations = [
            :takes,
          ]
        end
      end

      it 'does not do anything if no actual promise is made on time taken' do
        expect(PerformanceValidations).not_to receive(:report_failed_takes)
        expect(PerformanceValidations).to receive(:report_promise_passed)
        PerformancePromise.validate_promise('ActionController#index', [], 1, {})
      end

      context 'when an actual promise is made' do
        it 'reports a failure when a promise fails' do
          options = {
            :takes => 0.seconds,
          }
          expect(PerformanceValidations).to receive(:report_failed_takes).and_return(['', []])
          expect {
            PerformancePromise.validate_promise('ActionController#index', [], 1, options)
          }.to raise_error(PerformancePromise::BrokenPromise)
        end

        it 'reports a success when a promise passes' do
          options = {
            :takes => 1,
          }
          expect(PerformanceValidations).not_to receive(:report_failed_takes)
          expect(PerformanceValidations).to receive(:report_promise_passed)
          PerformancePromise.validate_promise('ActionController#index', [], 1, options)
        end
      end
    end
  end
end
