# frozen_string_literal: true

require_relative '../../helpers/appraisal_helper.rb'

describe Views::Files do
  before do
    appraisal = AppraisalHelper.build_appraisal
    @view_obj = Views::Files.new(appraisal.appraisal, nil)
  end

  it 'debuging' do
    binding.pry
  end
end
