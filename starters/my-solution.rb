# frozen_string_literal: true

# Sortbot Solver.
require 'net/http'
require 'json'

def main
  username = 'fmmendes'
  start = post_json('/sortbot/exam/start', login: username)
  set_path = start['nextSet']

  # get the first set
  next_set = get_json(set_path)

  # Answer each question, as log as we are correct
  loop do
    arr = next_set['question']
    instruction = next_set['message']

    if instruction == 'Sort these words by length, from longest to shortest.'
      arr.sort_by!(&:length)
      arr.reverse!
    elsif instruction == 'Sort these words by the number of vowels, from fewest vowels to most vowels. The vowels are: A,E,I,O,U.'
      arr.sort! do |a, b|
        a.count('aeiou') <=> b.count('aeiou')
      end
    elsif instruction == 'Sort these words by the number of consonants, from fewest consonants to most consonants. The consonants are every letter except: A,E,I,O,U.'
      arr.sort! do |a, b|
        a.length - a.count('aeiou') <=> b.length - b.count('aeiou')
      end
    elsif instruction == 'Sort these sentences by the number of words, from fewest words to most words.'
      arr.sort! do |a, b|
        a.split.size <=> b.split.size
      end
    else
      arr.sort!
    end

    solution = arr

    # send to sortbot
    formatted_solution = JSON.parse(solution.to_json)

    # puts formatted_solution
    solution_result = send_solution(set_path, formatted_solution)

    if solution_result['result'] == 'finished'
      complete_exam(solution_result)
    elsif solution_result['result'] == 'success'
      puts '.'
      set_path = solution_result['nextSet']
      next_set = get_json(set_path)
    else
      puts "\n💩\n"
      puts instruction
      puts formatted_solution.to_s
      puts "Sorry, that's not correct: #{solution_result['message']}\n\n"
      exit
    end
  end
end

def complete_exam(solution_result)
  puts "\n"
  puts "You did it! You completed the challenge in #{solution_result['elapsedTime']} milliseconds"
  puts "See your certificate at https://api.noopschallenge.com#{solution_result['certificate']}"
  puts "\n\nThank you for playing.\n\n"
  exit
end

def send_solution(path, solution)
  post_json(path, solution: solution)
end

# get data from the api and parse it into a ruby hash
def get_json(path)
  response = Net::HTTP.get_response(build_uri(path))
  result = JSON.parse(response.body)
  # puts "🤖 GET #{path}"
  # puts "HTTP #{response.code}"
  # puts JSON.pretty_generate(result)
  result
end

# post an answer to the noops api
def post_json(path, body)
  uri = build_uri(path)
  # puts "🤖 POST #{path}"
  # puts JSON.pretty_generate(body)

  post_request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  post_request.body = JSON.generate(body)

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(post_request)
  end

  # puts "HTTP #{response.code}"
  result = JSON.parse(response.body)
  # puts result[:result]
  result
end

def build_uri(path)
  URI.parse('https://api.noopschallenge.com' + path)
end

main
