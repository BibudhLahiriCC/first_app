# Class to access to PostgreSQL functions. Returned value depends on params and query result, see below.
#
# Currently supported options are:
#     :order => '1 desc' # to add order clause
#     :use_from => true  # to add "* from" for non-model function queries, which return records
#     :all => true       # to return not first but all found models
#     :cast => string    # to cast result (useful for functions, returning +setof record+)
#
# Call-patterns:
#
# A) Model loading from functions that return setof system known rowtype
#     PgProc.function(ModelClass[, options])
#         PgProc.get_descendants(ContentNode, 123)
#
#     PgProc.function(ModelClass, value[, options ])
#         PgProc.get_children(ContentNode, 123, :order => 'position', :all => true)
#
# returns either:
# * empty array if nothing found
# * first found model object, if found only one and +:all+ option is not set
# * array of model objects
#
# B) Values from functions
#
# PgProc.function(:type_symbol, value, [type_symbol2, value2, ...[, options]]) - for explicit parameter typecast
#     PgProc.array_append(:"int[]", '{1,2,3,4}', :int, 5) # => {1,2,3,4,5}
#
# PgProc.function(*args [, options])
#     PgProc.generate_series(1,10,2, :order => '1 desc') # => [9,5,7,3,2,1]
#
# PgProc.function() - for functions w/o params
#     PgProc.now()
#
# returns either:
# * empty string for +void+ functions
# * single value, if resultset has 1x1 dimension
# * array of values if resultset has Nx1 dimension (N>1)
# * array of rows otherwise
#
# Throws PGError, if function doesn't exist or wrong params supplied

class PgProc < ActiveRecord::Base
    set_table_name 'pg_catalog.pg_proc'
    set_primary_key 'oid'
    def readonly?
      true
    end

private

    def self.method_missing(meth_sym, *args)
      #meth_sym is a symbol. id2name returns the name corresponding to meth_sym.
      func_name = meth_sym.id2name
      super unless find(:first, :conditions => ['proname = ?', func_name])
      if ! args.empty? && args.last.is_a?(Hash)
        options = args.pop
        order_str = " ORDER BY #{options[:order]}" if options[:order]
      else
        options = {}
        order_str = nil
      end
      from_str = " * FROM " if options[:use_from]
      if args.empty?
        temp = connection.query("select #{from_str} #{func_name}() #{options[:cast]} #{order_str}")
      elsif args.first.is_a?(Class)
        model_klass = args.shift
        if args.length == 0
          temp = model_klass.find_by_sql("select * from  #{func_name}()  #{options[:cast]} #{order_str}")
        else
          temp = model_klass.find_by_sql("select * from  #{func_name}(#{quote_bound_value(args)})  #{options[:cast]} #{order_str}")
        end
        return temp if options[:all]
        return temp.length == 1 ? temp.first : temp
      else
          if args.length % 2 == 0 && args.first.is_a?(Symbol)
             temp = connection.query("select #{from_str} #{func_name}(#{quote_bound_value_types(args)}) #{options[:cast]} #{order_str}")
          else
             temp = connection.query("select #{from_str} #{func_name}(#{quote_bound_value(args)})  #{options[:cast]} #{order_str}")
        end
      end
      return temp.first.first if temp.length == 1 && temp.first.length == 1
      return temp.flatten if temp.length > 1 && temp.first.length == 1
      return temp
    end
    def self.quote_bound_value_types(value)
      i = true
      value.partition {|v| i = !i }.transpose.map{|v| "#{connection.quote(v[0])}::#{v[1]}"}.join(',')
    end

end
