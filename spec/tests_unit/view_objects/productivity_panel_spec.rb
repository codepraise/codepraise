# frozen_string_literal: true

require_relative '../../helpers/appraisal_helper.rb'

describe Views::ProductivityPanel do
  before do
    appraisal = AppraisalHelper.build_appraisal
    view_obj = Views::ProductivityPanel.new(appraisal.appraisal)
    binding.pry
  end

  describe 'test' do
    it do
    end
  end
end
