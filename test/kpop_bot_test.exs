defmodule KpopBotTest do
  use ExUnit.Case
  doctest KpopBot

  test "greets the world" do
    assert KpopBot.hello() == :world
  end
end
