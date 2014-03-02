require 'spec_helper'
require ROOT_PATH.join("lib/data_parsing/stroom_dal_chain.rb")

describe StroomDalChain do
  describe :can_handle? do
    subject { StroomDalChain.new.can_handle?(line) }

    context "when the line starts with 1-0:1.8.1" do
      let(:line) { "1-0:1.8.1(00557.379*kWh)" }

      it { should == true }
    end

    context "when the line starts with something else" do
      let(:line) { "1-0:1.8.2(00610.251*kWh)" }

      it { should == false }
    end
  end

  describe :handle do
    let(:output) { OpenStruct.new }
    let(:next_line) { "next line" }
    let(:lines) { ["1-0:1.8.1(00557.379*kWh)", next_line].to_enum }

    it "sets the correct amount in :stroom_dal" do
      subject.handle(lines, output)

      output.stroom_dal.should == 557.379.kWh
    end

    it "advances the enumerator" do
      subject.handle(lines, output)

      lines.next.should == next_line
    end
  end
end
