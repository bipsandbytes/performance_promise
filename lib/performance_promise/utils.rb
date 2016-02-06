module Utils
  def self.summarize_queries(db_queries)
    summary = Hash.new(0)
    db_queries.each do |query|
      summary[query.except(:duration)] += 1
    end
    summary
  end

  def self.guess_order(db_queries)
    order = []
    single_queries = 0
    queries_with_count = summarize_queries(db_queries)
    queries_with_count.each do |query, count|
      if count == 1
        single_queries += 1
      else
        if (lookup_field = /WHERE .*"(.*?_id)" = \?/.match(query[:sql]))
          klass = lookup_field[1].humanize
          order << "#{klass}.N.queries"
        else
          order << "n(???)"
        end
      end
    end

    if single_queries == 1
      order << '1.query'
    elsif single_queries > 1
      order << "#{single_queries}.queries"
    end
    order.join(" + ")
  end

  def self.colored(color, string)
    color =
      case color
      when :red
        "\e[31m"
      when :green
        "\e[32m"
      when :cyan
        "\e[36m"
      end
    end_color = "\e[0m"
    "#{color}#{string}#{end_color}"
  end
end
