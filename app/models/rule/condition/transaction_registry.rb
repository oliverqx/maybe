class Rule::Condition::TransactionRegistry
  include Rule::Condition::Sanitizable

  attr_reader :family

  def initialize(family)
    @family = family
  end

  def get_config(condition_type)
    config = definitions[condition_type.to_sym]
    ConditionConfig.new(**config)
  end

  def options
    definitions.map do |condition_type, data|
      [ data[:label], condition_type ]
    end
  end

  def as_json
    definitions.map do |condition_type, data|
      {
        input_type: data[:input_type],
        label: data[:label],
        condition_type: condition_type,
        operators: data[:operators],
        options: data[:options]
      }
    end
  end

  private
    ConditionConfig = Data.define(:input_type, :label, :operators, :options, :preparer, :builder)

    def definitions
      {
        transaction_name: {
          input_type: "text",
          label: "Name",
          operators: [ "like", "=" ],
          options: nil,
          preparer: ->(scope) { scope.with_entry },
          builder: ->(transaction_scope, operator, value) {
            expression = build_sanitized_where_condition("account_entries.name", operator, value)
            transaction_scope.where(expression)
          }
        },
        transaction_amount: {
          input_type: "number",
          label: "Amount",
          operators: [ ">", ">=", "<", "<=", "=" ],
          options: nil,
          preparer: ->(scope) { scope.with_entry },
          builder: ->(transaction_scope, operator, value) {
            expression = build_sanitized_where_condition("account_entries.amount", operator, value.to_d)
            transaction_scope.where(expression)
          }
        },
        transaction_merchant: {
          input_type: "select",
          label: "Merchant",
          operators: [ "=" ],
          options: family.assigned_merchants.pluck(:name, :id),
          preparer: ->(scope) { scope.left_joins(:merchant) },
          builder: ->(transaction_scope, operator, value) {
            expression = build_sanitized_where_condition("merchants.id", operator, value)
            transaction_scope.where(expression)
          }
        }
      }
    end
end
