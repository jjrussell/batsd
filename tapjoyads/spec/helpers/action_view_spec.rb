require 'spec_helper'

describe ActionView do

  context 'ActionView::Helpers::TranslationHelper.translate' do
    before :each do
      I18n.default_locale = :en
      I18n.backend.store_translations :en, :hello_world => "Hello, world."
      I18n.backend.store_translations :es, :hello_world => "Hola, mundo."
      I18n.backend.store_translations :en, :hello_name => "Hello, %{name}"
      I18n.backend.store_translations :es, :hello_name => "Hola, %{not_the_name}"
    end

    after :each do
      I18n.locale = nil
    end

    it 'uses the correct locale' do
      helper.t(:hello_world).should == "Hello, world."
      I18n.locale = :es
      helper.t(:hello_world).should == "Hola, mundo."
    end

    it 'falls back to the default locale on interpolation argument errors' do
      I18n.locale = :es
      helper.t(:hello_name, :not_the_name => "tapjoy").should == "Hola, tapjoy"
      helper.t(:hello_name, :name => "tapjoy").should == "Hello, tapjoy"
    end
  end

end
