# frozen_string_literal: true

require_relative '../../helpers/appraisal_helper.rb'

describe Views::Overview do
  before do
    appraisal = AppraisalHelper.build_appraisal
    @view_obj = Views::Overview.new(appraisal.appraisal)
  end

  it 'debug' do
    binding.pry
  end
end
