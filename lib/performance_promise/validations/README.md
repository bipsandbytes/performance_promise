# Creating your own validations

You can easily extend `performance_promise` by writing your own validations. You do it in 3 steps:

1. Write your validation
2. Register your validation
3. Enable your validation in configuration

## Write your validation
Create a new file in this directory, which simply defines two functions:

```ruby
module VALIDATION
  def validate_NAME(db_queries, render_time, promised)
    ...
  end
  
  def report_failed_NAME(db_queries, render_time, promised)
    ...
  end
end
```

* `VALIDATION`: A name for the module
* `NAME`: The symbol that will be used in the `Performance` promise. For example, if the `NAME` is `makes`, then the function name will be `validates_makes`, and the `Promise` will take an option `:makes`.
* `validates_NAME`: A function that is called if the a function makes a promise with that `NAME`. The function should return `true` if the validation fails i.e. the performance promise is broken.
* `report_failed_NAME`: A function called to report why the promise was broken, and possibly how to fix it. Should return an error message and a (possibly empty) backtrace.


Each of the function receives the same set of parameters:
* `db_queries`: An `array` of database queries which can be inspected.
* `render_time`: Time it took to render the view.
* `promised`: The performance guarantee made by the author.

See [time_taken_for_render](https://github.com/bipsandbytes/performance_promise/blob/master/lib/performance_promise/validations/time_taken_for_render.rb) for a simple example.

## Register your validation
You are now ready to register this plugin. Simply add this plugin to the list of validations in [performace_validations](https://github.com/bipsandbytes/performance_promise/blob/master/lib/performance_promise/performance_validations.rb):
```ruby
module PerformanceValidations
  ...
  extend VALIDATION
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
```
