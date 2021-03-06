require 'spec_helper'

RSpec.describe SmartProperties, 'intheritance' do
  context 'when used to build a class that has a required property with no default called :text whose getter is overriden' do
    subject(:klass) do
      DummyClass.new do
        property :text, required: true
        def text; "<em>#{super}</em>"; end
      end
    end

    specify "an instance of this class should raise an error during initilization if no value for :text has been specified" do
      expect { klass.new }.to raise_error(SmartProperties::InitializationError)
    end
  end

  context 'when modeling the following class hiearchy: Base > Section > SectionWithSubtitle' do
    let!(:base) do
      Class.new do
        attr_reader :content
        def initialize(content = nil)
          @content = content
        end
      end
    end
    let!(:section) { DummyClass.new(base) { property :title } }
    let!(:subsection) { DummyClass.new(section) { property :subtitle } }

    context 'the base class' do
      it('should not respond to #properties') { expect(base).to_not respond_to(:properties) }
    end

    context 'the section class' do
      it('should respond to #properties') { expect(section).to respond_to(:properties) }

      it "should expose the names of the properties through its property collection" do
        expect(section.properties.keys).to eq([:title])
      end

      it "should expose the the properties through its property collection" do
        properties = subsection.properties.values
        expect(properties.first).to be_kind_of(SmartProperties::Property)
        expect(properties.first.name).to eq(:title)
      end

      context 'an instance of this class' do
        subject { section.new }
        it { is_expected.to have_smart_property(:title) }
        it { is_expected.to_not have_smart_property(:subtitle) }
      end

      context 'an instance of this class when initialized with content' do
        subject(:instance) { section.new('some content') }
        it('should have content') { expect(instance.content).to eq('some content') }
      end
    end

    context 'the subsectionclass' do
      it('should respond to #properties') { expect(subsection).to respond_to(:properties) }

      it "should expose the names of the properties through its property collection" do
        expect(subsection.properties.keys).to eq([:title, :subtitle])
      end

      it "should expose the the properties through its property collection" do
        properties = subsection.properties.values
        expect(properties.first).to be_kind_of(SmartProperties::Property)
        expect(properties.first.name).to eq(:title)

        expect(properties.last).to be_kind_of(SmartProperties::Property)
        expect(properties.last.name).to eq(:subtitle)
      end

      context 'an instance of this class' do
        subject(:instance) { subsection.new }
        it { is_expected.to have_smart_property(:title) }
        it { is_expected.to have_smart_property(:subtitle) }

        it 'should have content, a title, and a subtile when initialized with these parameters' do
          instance = subsection.new('some content', title: 'some title', subtitle: 'some subtitle')
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')

          instance = subsection.new('some content') do |s|
            s.title, s.subtitle = 'some title', 'some subtitle'
          end
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
        end
      end
    end

    context 'when the section class is extended with a property at runtime' do
      before { section.send(:property, :type) }

      context 'the section class' do
        subject { section }
        it { is_expected.to have_smart_property(:type) }

        it 'should have content, a title, and a type when initialized with these parameters' do
          instance = subsection.new('some content', title: 'some title', type: 'important')
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.type).to eq('important')

          instance = subsection.new('some content') do |s|
            s.title, s.type = 'some title', 'important'
          end
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.type).to eq('important')
        end
      end

      context 'the subsection class' do
        subject { subsection }
        it { is_expected.to have_smart_property(:type) }

        it 'should have content, a title, a subtitle, and a type when initialized with these parameters' do
          instance = subsection.new('some content', title: 'some title', subtitle: 'some subtitle', type: 'important')
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
          expect(instance.type).to eq('important')

          instance = subsection.new('some content') do |s|
            s.title, s.subtitle, s.type = 'some title', 'some subtitle', 'important'
          end
          expect(instance.content).to eq('some content')
          expect(instance.title).to eq('some title')
          expect(instance.subtitle).to eq('some subtitle')
          expect(instance.type).to eq('important')
        end
      end
    end

    context 'when the section class overrides the getter of the title property and uses super to retrieve the property\'s original value' do
      before do
        section.class_eval do
          def title; super.to_s.upcase; end
        end
      end

      specify 'an instance of the section class should transform the value as defined in the overridden getter' do
        instance = section.new(title: 'some title')
        expect(instance.title).to eq('SOME TITLE')
        expect(instance[:title]).to eq('SOME TITLE')
      end

      specify 'an instance of the subsection class should transform the value as defined in the overridden getter in the superclass' do
        instance = subsection.new(title: 'some title')
        expect(instance.title).to eq('SOME TITLE')
        expect(instance[:title]).to eq('SOME TITLE')
      end
    end
  end
end
