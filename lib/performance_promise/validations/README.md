# Creating your own validations

You can easily extend `performance_promise` by writing your own validations. You do it in 3 steps:

1. Write your validation
2. Register your validation
3. Enable your validation in configuration

## Write your validation
Create a new file in this directory, with a single function:

```ruby
module MODULE_NAME
  def validate_NAME(db_queries, render_time, promised)
    ...
  end
end
```

* `MODULE_NAME`: A name for the module.
* `NAME`: The symbol that will be used in the `Performance` promise. For example, if the `NAME` is `makes`, then the function function name will be `validates_makes`, and the `Promise` will take an option `:makes`.
* `validates_NAME`: A function that is called if the a function makes a promise with that `NAME`.

The function takes 3 parameters:
  * `db_queries`: An `array` of database queries which can be inspected.
  * `render_time`: Time it took to render the view.
  * `promised`: The performance guarantee made by the author.

And returns 3 parameters:
  * `passes`: Whether the promised made by the author in `promised` is upheld.
  * `error_message`: An error message to show to the user explaining why the promise failed, and a best guess of how to fix it, if possible.
  * `backtrace`: If possible, an `array` showing the codepath that caused the promise to be broken.

See [time_taken_for_render](https://github.com/bipsandbytes/performance_promise/blob/master/lib/performance_promise/validations/time_taken_for_render.rb) for a simple example.

## Register your validation
You are now ready to register this plugin. Simply add this plugin to the list of validations in [performace_validations](https://github.com/bipsandbytes/performance_promise/blob/master/lib/performance_promise/performance_validations.rb):
```ruby
module PerformanceValidations
  ...
  extend MODULE_NAME
  ...
end
```

## Enable your validation in configuration
You are now ready to include this validation in your configuration file:
```ruby
PerformancePromise.configure do |config|
  config.enable = true
  config.validations = [
    ...
    :NAME,
  ]
end
```
