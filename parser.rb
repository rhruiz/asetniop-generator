#!/usr/bin/env ruby

require 'set'

class Tokenizer
  TOKEN_TYPES = [
    [:def, /\bdef\b/],
    [:end, /\bend\b/],
    [:identifier, /\b[a-z_A-Z]+\b/],
    [:integer, /\b[0-9]+\b/],
    [:oparen, /\(/],
    [:comma, /,/],
    [:cparen, /\)/]
  ]

  def initialize(code)
    @code = code
    @tokens = []
  end

  def tokenize
    until @code.empty?
      @tokens << find_token

      @code = @code.strip
    end

    @tokens
  end

  def find_token
    TOKEN_TYPES.each do |type, re|
      match = @code.match(/\A(#{re})/)
      if match
        value = match[1]
        @code = @code[value.length..-1]
        return Token.new(type, value)
      end
    end
  end
end

Token = Struct.new(:type, :value)

class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    parse_expr
  end

  def parse_def
    consume(:def)
    name = consume(:identifier).value
    arg_names = parse_arg_names
    body = parse_expr
    consume(:end)

    DefNode.new(name, arg_names, body)
  end

  def parse_arg_names
    arg_names = []
    consume(:oparen)
    if peek(:identifier)
      arg_names << consume(:identifier).value
      while peek(:comma)
        consume(:comma)
        arg_names << consume(:identifier).value
      end
    end

    consume(:cparen)
    arg_names
  end

  def parse_expr
    if peek(:integer)
      parse_integer
    elsif peek(:identifier) && peek(:oparen, 1)
      parse_call
    else
      parse_var_ref
    end
  end

  def parse_integer
    IntegerNode.new(consume(:integer).value.to_i)
  end

  def parse_call
    name = consume(:identifier)

    arg_exprs = parse_arg_exprs

    CallNode.new(name.value, arg_exprs)
  end

  def parse_var_ref
    name = consume(:identifier).value

    VarRefNode.new(name)
  end

  def parse_arg_exprs
    arg_exprs = []
    consume(:oparen)

    if !peek(:cparen)
      arg_exprs << parse_expr
      while peek(:comma)
        consume(:comma)
        arg_exprs << parse_expr
      end
    end

    consume(:cparen)
    arg_exprs
  end

  def peek(type, offset = 0)
    @tokens.fetch(offset).type == type
  end

  def consume(type)
    token = @tokens.shift
    if token.type == type
      token
    else
      raise RuntimeError.new(
        "Expected token type #{type}, but got #{token.type}"
      )
    end
  end
end

DefNode = Struct.new(:name, :args, :body)
IntegerNode = Struct.new(:value)
CallNode = Struct.new(:name, :arg_exprs)
VarRefNode = Struct.new(:name)

tokens = Tokenizer.new(File.read("keymap.c")).tokenize
tree = Parser.new(tokens).parse

combos = [15..18, 53..56].flat_map(&:to_a).flat_map do |i|
  [15..18, 53..56].flat_map(&:to_a).map do |j|
    left_key = tree.arg_exprs.first.arg_exprs[i].arg_exprs.last.name
    right_key = tree.arg_exprs.first.arg_exprs[j].arg_exprs.last.name
    layer = tree.arg_exprs.first.arg_exprs[i].arg_exprs[0].value - 7
    becomes = tree.arg_exprs[layer].arg_exprs[j].name

    [Set.new([left_key, right_key]), becomes]
  end
end
  .reject { |(ks, target)| target == "KC_TRANSPARENT" || ks.length == 1 }
  .uniq
  .map.with_index { |(s,c), i| (a,b) = s.to_a; ["const uint16_t PROGMEM _combo_#{i}[] = {#{a}, #{b}, COMBO_END};", "COMBO(_combo_#{i}, #{c}),"]  }.reduce([[],[]]) { |(left, right), elem| left << elem[0]; right << elem[1]; [left, right] }.map { |x| x.join("\n") }

puts combos

