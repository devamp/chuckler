// Unit tests for the word filter and the report threshold (no emulator).

const assert = require("assert");
const {containsBlockedWords, shouldHide, targetKey} =
    require("../moderation");

describe("word filter", () => {
  it("catches listed words, plurals and letter swaps", () => {
    assert.ok(containsBlockedWords("you are a slut"));
    assert.ok(containsBlockedWords("SLUTS everywhere"));
    assert.ok(containsBlockedWords("p0rn"));
    assert.ok(containsBlockedWords("what a wh0re!"));
    assert.ok(containsBlockedWords("k y s"));
  });

  it("leaves ordinary words alone", () => {
    for (const ok of ["class", "Scunthorpe", "grape", "therapist",
      "analysis", "cocktail", "Moby Dick", "raccoon", "hell yeah",
      "damn that's good", "a cumulative score", ""]) {
      assert.ok(!containsBlockedWords(ok), ok);
    }
  });
});

describe("reports", () => {
  it("hides at three reporters, or one when the text is flagged", () => {
    assert.ok(!shouldHide(2, false));
    assert.ok(shouldHide(3, false));
    assert.ok(shouldHide(1, true));
    assert.ok(!shouldHide(0, true));
  });

  it("keys moderation docs by type and id", () => {
    assert.strictEqual(targetKey({targetType: "comment", targetId: "c1"}),
        "comment_c1");
  });
});
