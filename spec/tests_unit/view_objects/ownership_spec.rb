# frozen_string_literal: true

require_relative '../../helpers/appraisal_helper.rb'

describe Views::Ownership do
  before do
    appraisal = AppraisalHelper.build_appraisal
    @view_obj = Views::Ownership.new(appraisal.appraisal)
  end

  it 'debugging' do
    binding.pry
  end
end
