module Math
  def self.percentage(x, y)
    return y if y.zero?

    ((x.to_f / y) * 100).round
  end

  def self.average(array)
    array_len = array.count

    return array_len if array_len.zero?

    (array.sum / array_len).round
  end

  def self.divide(x, y)
    return 0 if y.zero?

    (x / y).round
  end
end
