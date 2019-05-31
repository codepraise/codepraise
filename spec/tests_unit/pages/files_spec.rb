# frozen_string_literal: true

require_relative '../../helpers/appraisal_helper.rb'

describe Views::Files do
  before do
    appraisal = AppraisalHelper.build_appraisal.appraisal
    @page = Views::PageFactory.create_page(appraisal, 'files')
  end

  it 'debugging' do
    binding.pry
  end

  describe '#a_board' do
    it 'should have some elements' do
      _(@page.a_board.elements).wont_be_empty
      _(@page.a_board.elements.map(&:to_element)).wont_be_empty
    end
  end

  describe '#b_board' do
    it 'should have some elements' do
      _(@page.b_board.elements).wont_be_empty
      _(@page.b_board.elements.map(&:to_element)).wont_be_empty
    end
  end

  describe '#c_board' do
    it 'should have some elements' do
      _(@page.c_board.elements).wont_be_empty
      _(@page.c_board.elements.map(&:to_element)).wont_be_empty
    end
  end

  describe '#folder_tree' do
    it 'sholde create folder tree element' do
      _(@page.folder_tree.to_element).wont_be_nil
    end
  end
end
