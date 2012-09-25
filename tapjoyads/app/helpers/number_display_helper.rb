module NumberDisplayHelper
  UNITS = {:unit => "", :ten => "", :hundred => "", :thousand => "K", :million => "M",
           :billion => "B", :trillion => "T", :quadrillion => "P"}

  def numeric_display(number, precision=2)
    number_to_human(number, :units => UNITS, :precision => precision, :significant => false, :format => "%n%u")
  end
end
