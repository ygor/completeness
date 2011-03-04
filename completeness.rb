module Completeness

  def self.included(base)
    base.instance_eval do
      class_inheritable_hash :completeness_checks
      cattr_accessor :completeness_attributes
      attr_accessor :incomplete_attributes
    end
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def define_completeness(name = :default, &checks_block)
      self.completeness_checks ||= {}
      self.completeness_attributes ||= {}
      checks = Completeness::Builder.build(self, &checks_block)
      self.completeness_checks[name] = checks
      self.completeness_attributes[name] = checks.map {|h| h[:attribute]}
    end
  end

  # Instance methods
  def complete?(*names)
    self.incomplete_attributes = []
    names = (self.class.completeness_checks || {}).keys if names.empty?
    result = true
    names.each do |name|
      raise "Completeness: group with name #{name} does not exist." if (self.class.completeness_checks[name].nil?)
      self.class.completeness_checks[name].each do |check|
        if (check[:unless].blank? && check[:if].blank?) || (check[:if] && check[:if].call(self)) || (check[:unless] && !check[:unless].call(self))
          complete = check[:check].call(self.send(check[:attribute]))
          self.incomplete_attributes << check[:attribute] unless complete
          result = result && complete
        end
      end
    end
    result
  end
  
  class Builder < Struct.new(:completeness_checks, :model)
    def self.build(model, &block)
      b = self.new([], model)
      b.instance_eval(&block)
      b.completeness_checks
    end
    
    protected
    
    def check(*attributes)
      options = attributes.extract_options!
      attributes.each do |attribute|
        if options[:with].nil?
          association = self.model.reflect_on_association(attribute)
          unless association.nil?
            case association.macro
            when :belongs_to, :has_one
              with = lambda {|r| r.present? && r.complete? }
            when :has_many
              with = lambda {|rs| rs.reject {|r| !r.complete? }.length >= 1 }
            end
          end
        end
        self.completeness_checks << {:attribute => attribute, :check => options[:with] || with || lambda {|a| a.present?}, :unless => options[:unless], :if => options[:if]}
      end
    end    
  end  
end