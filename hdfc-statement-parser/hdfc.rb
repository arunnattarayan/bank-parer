require 'rubygems'
require 'pdf/reader'
require 'pry'
require 'facets'
require 'date'

HDFC_HEADER = ["Date", "Narration", "Chq", "Ref", "No", "Value", "Dt", "Withdrawal", "Amt", "Deposit", "Amt", "Closing", "Balance"]
END_STATEMENT = "*Closing balance includes funds earmarked for hold and uncleared funds"
STATEMENT_NAME = 'Statement of account'

def check_valid_date(date) 
  val = false;
  begin
    Date.strptime(date, '%d/%m/%y')
    val = true
  rescue 
  end
  return val
end

def find_cridit_debit(line)
  val = '';
  amount = 0;
  break_now = false;
  date_count = 0;
  space_count = 0;
  line.split(/\s/).each do |value|
    if (value.length > 0)
      if(date_count == 2) 
        val = space_count > 15 ? 'Deposit' : 'Withdrawal';
        break_now = true;
        amount = value.sub(',','').to_f;
      end
      break if break_now;
      if(check_valid_date(value))
        date_count +=1
        space_count = 0;
      end
    elsif(date_count == 2)
      space_count += 1;
    end
  end
  return val,amount
end

def check_next_line_message(line)
  message = nil;
  if (line)
    isValid = check_valid_date(line.strip.split(/\s+/)[0]) 
    if(!isValid)
      message = line.strip
    end
    message
  end
  message
end

def page_parse(page, page_index)
  content = false;
  record = []
  lines = page.text.split(/\n+/)
  skip_next = false;
  lines.each_with_index do |line, index|
    line = line.strip
    message = '';
    if content
      message = check_next_line_message(lines[index+ 1])
      data = line.split("  ").reject(&:blank?)
      next if data.length < 2  
      content = false if message == "HDFC BANK LIMITED" || message == END_STATEMENT 
      date = data[0];
      narration = data[1].to_s;
      message = narration + message if message
      transaction_type, amount = find_cridit_debit(line)
      record.push({date: date, message: message,transaction_type: transaction_type, narration: narration, amount: amount}) if amount != 0
    end
    if line.split(/\W+/).frequency == HDFC_HEADER.frequency || line.include?(STATEMENT_NAME)
      content = true
    end
  end
  record
end

def file_parse(name)
  reader = PDF::Reader.new(name)
  puts '++++++++++++++++++++++++++++++++++++++++++++++++++++'
  puts '++++++++++File Readed+++++++++++++++++++++++++++++++'
  puts '++++++++++++++++++++++++++++++++++++++++++++++++++++'
  record = [];
  reader.pages.each_with_index  do |page, index|
    record.concat(page_parse(page, index))
  end
  puts record.to_json
  return record
end


file_parse("/home/arun/Documents/bankDoc/arun-March-to-Dec-2018.pdf")
