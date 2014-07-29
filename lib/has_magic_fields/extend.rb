module HasMagicFields
  module Extend extend ActiveSupport::Concern
    module ClassMethods
      def has_magic_fields(options = {})
        # Associations
        has_many :magic_attribute_relationships, :as => :owner, :dependent => :destroy
        has_many :magic_attributes, :through => :magic_attribute_relationships, :dependent => :destroy
        
        # Inheritence
        cattr_accessor :inherited_from

        # if options[:through] is supplied, treat as an inherited relationship
        if self.inherited_from = options[:through]
          class_eval do
            def inherited_magic_fields
              raise "Cannot inherit MagicFields from a non-existant association: #{@inherited_from}" unless self.class.method_defined?(inherited_from)# and self.send(inherited_from)
              self.send(inherited_from).magic_fields
            end
          end
          alias_method :magic_fields, :inherited_magic_fields unless method_defined? :magic_fields

        # otherwise the calling model has the relationships
        else
          has_many :magic_field_relationships, :as => :owner, :dependent => :destroy
          has_many :magic_fields, :through => :magic_field_relationships, :dependent => :destroy
        end
        
      end
    end

    included do
      
      def method_missing(method_id, *args)
        super(method_id, *args)
      rescue NoMethodError
        
        method_name = method_id.to_s
        attr_names = magic_fields.map(&:name)
        super(method_id, *args) unless attr_names.include?(method_name) or (md = /[\?|\=]/.match(method_name) and attr_names.include?(md.pre_match))

        if method_name =~ /=$/
          var_name = method_name.gsub('=', '')
          value = args.first
          write_magic_attribute(var_name,value)
        else
          read_magic_attribute(method_name)
        end
      end

      # Load the MagicAttribute(s) associated with attr_name and cast them to proper type.
      def read_magic_attribute(field_name)
        field = find_magic_field_by_name(field_name)
        attribute = find_magic_attribute_by_field(field)
        value = (attr = attribute.first) ?  attr.to_s : field.default
        value.nil?  ? nil : field.type_cast(value)
      end

      def write_magic_attribute(field_name, value)
        field = find_magic_field_by_name(field_name)
        existing = find_magic_attribute_by_field(field) 
        (attr = existing.first) ? update_magic_attribute(attr, value) : create_magic_attribute(field, value)
      end
      
      def find_magic_attribute_by_field(field)
        magic_attributes.to_a.find_all {|attr| attr.magic_field_id == field.id}
      end
      
      def find_magic_field_by_name(attr_name)
        magic_fields.to_a.find {|column| column.name == attr_name}
      end
      
      def create_magic_attribute(magic_field, value)
        magic_attributes << MagicAttribute.create(:magic_field => magic_field, :value => value)
      end
      
      def update_magic_attribute(magic_attribute, value)
        magic_attribute.update_attributes(:value => value)
      end
    end

  end
end


