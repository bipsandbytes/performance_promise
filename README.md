# Performance Promise
The `performance_promise` gem enables you to annotate and validate the performance of your Rails actions.

You can declare the performance characteristics of your Rails actions in code (right next to the action definition itself), and `performance_promise` will monitor and validate the promise. If the action breaks the promise, the `performance_promise` gem will alert you and provide a helpful suggestion with a passing performance annotation.

You may also choose to enable a default/minimum performance promise for _all_ actions. You can reap all the benefits of performance validation without having to make any changes to code except tagging expensive actions.

## Installation
You can install it as a gem:
```sh
gem install performance_promise
```

or add it to a Gemfile (Bundler):
```sh
gem "performance_promise", :group => "development"
```

## Building
You can build the gem yourself:
```sh
gem build performance_promise.gemspec
```

## Configuration
For safety, `performance_promise` is disabled by default. To enable it, create a new file `config/initializers/performance_promise.rb` with the following code:
```ruby
require 'performance_promise'

PerformancePromise.configure do |config|
  config.enable = true
  # config.untagged_methods_are_speedy = true
  # config.speedy_promise = {
  #   :max_queries => 2,
  # }
  # config.allowed_environments = [
  #   'development',
  #   'test',
  # ]
  # config.validate_number_of_queries = true
  # config.logger = Rails.logger
  # config.throw_exception = false
end
PerformancePromise.start
```

## Usage
To understand how to use `performance_promise`, let's use a simple [Blog App][rails-getting-started]. A `Blog` has `Article`s, each of which may have one or more `Comment`s.

Here is a simple controller:
```ruby
class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end
end
```
Assuming your routes and views are setup, you should be able to succesfully visit `/articles`.

You can annotate this action with a promise of how many database queries the action will make so:
```ruby
  Performance 1.query
  def index
    @articles = Article.all
  end
```
Visit `/articles` to confirm that the view is rendered successfully again.

Now suppose, you make the view more complex
```ruby
  Performance 1.query
  def index
    @articles = Article.all
    @total_comments = 0
    @articles.each do |article|
      @total_comments += article.comments.length
    end
    puts @total_comments
  end
```
Visiting `/articles` now will throw an exception. The exception tells you that the performance of your view does not respect the annotation promise.

Update the annotation:
```ruby
  Performance 1.query + Article.count.queries
  def index
    @articles = Article.all
    @total_comments = 0
    @articles.each do |article|
      @total_comments += article.comments.length
    end
    puts @total_comments
  end
```
Now that you have annotated the action correctly, visiting `/articles` renders successfully.

## Advanced configuration
`performance_promise` opens up more functionality through configuration variables:

#### `allowed_environments: array`
By default, `performance_promise` runs only in `development` and `testing`. This ensures that you can identify issues when developing or running your test-suite. Be very careful about enabling this in `production` – you almost certainly don't want to.

#### `throw_exception: bool`
Tells `performance_promise` whether to throw an exception. Set to `true` by default, but can be overriden if you simply want to ignore failing cases (they will still be written to the log).

#### `speedy_promise: hash`
If you do not care to determine the _exact_ performance of your action, you can still simply mark it as `Speedy`:
```ruby
  Speedy()
  def index
    ...
  end
```
A `Speedy` action is supposed to be well behaved, making lesser than `x` database queries, and taking less than `y` to complete. You can set these defaults using this configuration parameter.

#### `untagged_methods_are_speedy: bool`
By default, actions that are not annotated aren't validated by `performance_promise`. If you'd like to force all actions to be validated, one option is to simply default them all to be `Speedy`. This allows developers to make _no_ change to their code, while still reaping the benefits of performance validation. Iff a view fails to be `Speedy`, then the developer is forced to acknowledge it in code.

[rails-getting-started]: <http://guides.rubyonrails.org/getting_started.html>
