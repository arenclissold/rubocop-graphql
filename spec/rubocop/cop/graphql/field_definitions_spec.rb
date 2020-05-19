# frozen_string_literal: true

RSpec.describe RuboCop::Cop::GraphQL::FieldDefinitions do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      "GraphQL/FieldDefinitions" => {
        "EnforcedStyle" => enforced_style,
        "SupportedStyles" => [
          "group_definitions",
          "define_resolver_after_definition"
        ]
      }
    )
  end

  context "when EnforcedStyle is group_definitions" do
    let(:enforced_style) { "group_definitions" }

    it "not registers an offense" do
      expect_no_offenses(<<~RUBY)
        class UserType < BaseType
          field :first_name, String
          field :last_name, String
        end
      RUBY
    end

    context "when field definitions are not grouped together" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class UserType < BaseType
            field :first_name, String

            def first_name
              object.contact_data.first_name
            end

            field :last_name, String
            ^^^^^^^^^^^^^^^^^^^^^^^^ Group all field definitions together.

            def last_name
              object.contact_data.last_name
            end
          end
        RUBY
      end
    end
  end

  context "when EnforcedStyle is define_resolver_after_definition" do
    let(:enforced_style) { "define_resolver_after_definition" }

    it "not registers an offense" do
      expect_no_offenses(<<~RUBY)
        class UserType < BaseType
          field :first_name, String

          def first_name
            object.contact_data.first_name
          end

          field :last_name, String

          def last_name
            object.contact_data.last_name
          end
        end
      RUBY
    end

    context "when :resolver is configured" do
      it "not registers an offense" do
        expect_no_offenses(<<~RUBY)
          class UserType < BaseType
            field :first_name, String, null: true, resolver: FirstNameResolver
            field :last_name, String

            def last_name
              object.contact_data.last_name
            end
          end
        RUBY
      end
    end

    context "when :method is configured" do
      it "not registers an offense" do
        expect_no_offenses(<<~RUBY)
          class UserType < BaseType
            field :first_name, String, null: true, method: :contact_first_name
            field :last_name, String

            def last_name
              object.contact_data.last_name
            end
          end
        RUBY
      end
    end

    context "when :hash_key is configured" do
      it "not registers an offense" do
        expect_no_offenses(<<~RUBY)
          class UserType < BaseType
            field :first_name, String, null: true, hash_key: :name1
            field :last_name, String

            def last_name
              object.contact_data.last_name
            end
          end
        RUBY
      end
    end

    context "when resolver method is not defined right after field definition" do
      it "registers offenses" do
        expect_offense(<<~RUBY)
          class UserType < BaseType
            field :first_name, String
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Define resolver method after field definition.
            field :last_name, String
            ^^^^^^^^^^^^^^^^^^^^^^^^ Define resolver method after field definition.

            def first_name
              object.contact_data.first_name
            end

            def last_name
              object.contact_data.last_name
            end
          end
        RUBY
      end

      context "when custom :resolver_method is configured for field" do
        it "registers offenses" do
          expect_offense(<<~RUBY)
            class UserType < BaseType
              field :first_name, String, resolver_method: :custom_first_name
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Define resolver method after field definition.
              field :last_name, String
              ^^^^^^^^^^^^^^^^^^^^^^^^ Define resolver method after field definition.

              def custom_first_name
                object.contact_data.first_name
              end

              def last_name
                object.contact_data.last_name
              end
            end
          RUBY
        end
      end
    end
  end
end
