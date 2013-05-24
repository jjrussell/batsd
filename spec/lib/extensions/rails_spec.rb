require 'spec_helper'

# since we're creating new classes, this is easier / less verbose than using rspec stubbing methods
# (we need to override a few methods to avoid hitting the db)
class Parent < ActiveRecord::Base;
  def attributes_from_column_definition; { 'id' => nil }; end
  def quoted_id; '`parents`.`id`'; end
  def add_to_transaction; nil; end
  def create; _run_create_callbacks; end
end

class Child < ActiveRecord::Base
  def self.attribute_methods_generated?; true; end
  def attributes_from_column_definition; { 'id' => nil, 'parent_id' => nil }; end
end

describe ActiveRecord::AutosaveAssociation do

  context '.has_one_association' do
    context 'with :required => true' do
      before :each do
        class Parent; has_one :child, :required => true; end
      end

      describe 'with an invalid child record' do
        it 'should raise an error' do
          parent = Parent.new
          parent.build_child

          # see implementation... alias_method_chain was used, and there's no need to test pre-existing functionality
          # also, by stubbing this, we ensure that the child record won't be persisted, which is what we're testing for
          parent.stub(:save_has_one_association_without_required_check)

          lambda { parent.save!(:validate => false) }.should raise_error(ActiveRecord::RecordNotSaved, 'Unable to save child association')
        end
      end

      describe 'without a child record instantiated' do
        it 'should raise an error' do
          parent = Parent.new

          lambda { parent.save!(:validate => false) }.should raise_error(ActiveRecord::RecordNotSaved, 'Required association: child not present')
        end
      end
    end
  end

end
