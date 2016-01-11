# Performance Promise
The `performance_promise` gem enables you to annotate and validate the performance of your Rails actions.

You can declare the performance characteristics of your Rails actions in code (right next to the action definition itself), and `performance_promise` will monitor and validate the promise. If the action breaks the promise, the `performance_promise` gem will alert you and provide a helpful suggestion with a passing performance annotation.

You may also choose to enable a default/minimum performance promise for _all_ actions. You can reap all the benefits of performance validation without having to make any changes to code except tagging expensive actions.

Example syntax:
```ruby
class ArticlesController < ApplicationController

  Performance :makes => 1.query,
              :takes => 1.second
  def index
    # ...
  end

  Performance :makes => 1.query + Article.N.queries,
              :takes => 5.seconds
  def expensive_action
    # ...
  end
end
```


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
require 'performance_promise/performance.rb'

PerformancePromise.configure do |config|
  config.enable = true
  # config.validations = [
  #   :makes,  # validate the number of DB queries made
  # ]
  # config.untagged_methods_are_speedy = true
  # config.speedy_promise = {
  #   :makes => 2,
  # }
  # config.allowed_environments = [
  #   'development',
  #   'test',
  # ]
  # config.logger = Rails.logger
  # config.throw_exception = true
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
class ArticlesController < ApplicationController

  Performance :makes => 1.query
  def index
    @articles = Article.all
  end

end
```
Visit `/articles` to confirm that the view is rendered successfully again.

Now suppose, you make the view more complex, causing it to execute more database queries
```ruby
  Performance :makes => 1.query
  def index
    @articles = Article.all
    @total_comments = 0
    @articles.each do |article|
      @total_comments += article.comments.length
    end
    puts @total_comments
  end
```
Since the performance annotation has not been updated, visiting `/articles` now will throw an exception. The exception tells you that the performance of your view does not respect the annotation promise.

![alt tag](http://i.imgur.com/S5unAoJ.png)

Let's update the annotation:
```ruby
  Performance :makes => 1.query + Article.N.queries
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


## FAQ
> **What is the strange syntax? Is it a function call? Is it a method?**

We borrow the coding style from Python's `decorators`. This style allows for a function to be wrapped by another. This is a great use case for that style since it allows for us to express the annotation right above the function definition.

Credit goes to [Yehuda Katz][yehuda-katz] for the [port of decortators][ruby-decorators] into Ruby.

> **Will this affect my production service?**

By default, `performace_promise` is applied only in `development` and `test` environments. You can choose to override this, but is strongly discouraged.


> **What are some other kinds of performance guarantees that I can make with `performance_promise`?**

In addition to promises about the number of database queries, you can also make promises on how long the entire view will take to render, and whether it performs any table scans.
```ruby
  Performance :makes => 1.query + Article.N.queries,
              :takes => 1.second,
              :full_tables_scans => [Article]
  def index
    ...
  end
```

If you come up with other validations that you think will be useful, please consider sharing it with the community by [writing your own plugin here](https://github.com/bipsandbytes/performance_promise/tree/master/lib/performance_promise/validations), and raising a Pull Request.

> **Is this the same as [Bullet][bullet] gem?**

[Bullet][bullet] is a great piece of software that allows developers to help identify N + 1 queries and unused eager loading. It does this by watching your application in development mode, and alerting you when it does either of those things.

`performance_promise` can be tuned to not only identify N + 1 queries, but can also alert whenever there's _any_ change in performance.  It allows you to identify expensive actions irrespective of their database query profile.

`performance_promise` also has access to the entire database query object. In the future, `performance_promise` can be tuned to perform additonal checks like how long the most expensive query took, whether the action performed any table scans (available through an `EXPLAIN`) etc.

Finally, the difference between `bullet` and `performance_promise` is akin to testing by refreshing your browser and testing by writing specs. `performance_promise` encourages you to specify your action's performance by declaring it in code itself. This allows both  code-reviewers as well as automated tests to verify your code's performance.

[rails-getting-started]: <http://guides.rubyonrails.org/getting_started.html>
[bullet]: <https://github.com/flyerhzm/bullet>
[yehuda-katz]: <http://yehudakatz.com/>
[ruby-decorators]: <http://yehudakatz.com/2009/07/11/python-decorators-in-ruby/>
