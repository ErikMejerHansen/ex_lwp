defmodule ExLWP.SpecTest do
  use ExUnit.Case, async: true

  alias ExLWP.Spec

  describe "Given the spec" do
    test "when read, then it has requirements with unique IDs" do
      requirements = Spec.requirements()

      assert %{id: "ARCH-1", section: "Architecture"} = hd(requirements)
      assert Enum.all?(requirements, &(&1.text =~ "shall"))
    end

    test "when compared with the reviews, then every review is for a requirement in it" do
      assert Spec.unknown_ids(Spec.requirements(), %{}, Spec.reviews()) == []
    end
  end

  describe "Given a requirement" do
    setup do
      %{requirement: %{id: "ARCH-1", section: "Architecture", text: "The ExLWP shall work"}}
    end

    test "when all its tests pass, then it is tested", %{requirement: requirement} do
      assert [%{status: :tested, tests: 2}] =
               Spec.status([requirement], %{"ARCH-1" => [:passed, :passed]}, %{})
    end

    test "when any of its tests fail, then it is failing, even if reviewed",
         %{requirement: requirement} do
      assert [%{status: :failing}] =
               Spec.status([requirement], %{"ARCH-1" => [:passed, :failed]}, %{"ARCH-1" => "ok"})
    end

    test "when it has a review but no tests, then it is reviewed", %{requirement: requirement} do
      assert [%{status: :reviewed, review: "ok"}] =
               Spec.status([requirement], %{}, %{"ARCH-1" => "ok"})
    end

    test "when it has neither tests nor a review, then it is open",
         %{requirement: requirement} do
      assert [%{status: :open}] = Spec.status([requirement], %{"ARCH-1" => [:skipped]}, %{})
    end
  end

  describe "Given tests or reviews that refer to IDs missing from the spec" do
    test "when checked, then those IDs are reported" do
      requirements = [%{id: "ARCH-1", section: "Architecture", text: "The ExLWP shall work"}]

      assert Spec.unknown_ids(requirements, %{"ARCH-1" => [], "ARCH-9" => []}, %{"OLD-1" => "x"}) ==
               ["ARCH-9", "OLD-1"]
    end
  end
end
