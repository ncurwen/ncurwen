require "test_helper"

class WeddingTest < ActiveSupport::TestCase
  # Counted in the venue's zone, not the server's, so the number ticks over at
  # midnight in London, Ontario rather than at midnight UTC.
  test "counts whole days to the party in the venue's timezone" do
    travel_to Wedding::STARTS_AT - 3.days do
      assert_equal 3, Wedding.days_away
    end
  end

  test "clamps at zero rather than counting backwards" do
    travel_to Wedding::STARTS_AT + 5.days do
      assert_equal 0, Wedding.days_away
    end
  end

  test "counts to an arbitrary date so components can be tested against their own" do
    from = Time.zone.local(2026, 1, 1)

    assert_equal 10, Wedding.days_away(to: from + 10.days, from: from)
  end

  test "builds a calendar file with CRLF line endings, as RFC 5545 requires" do
    ics = Wedding.to_ics

    assert ics.start_with?("BEGIN:VCALENDAR\r\n")
    assert ics.end_with?("END:VCALENDAR\r\n")
  end

  # UTC instants rather than a TZID: naming a zone obliges us to ship a matching
  # VTIMEZONE block, and strict clients reject the file without one.
  test "pins the event to UTC instants" do
    ics = Wedding.to_ics

    assert_match(/\r\nDTSTART:\d{8}T\d{6}Z\r\n/, ics)
    assert_match(/\r\nDTEND:\d{8}T\d{6}Z\r\n/, ics)
    assert_no_match(/TZID/, ics)
  end

  # RFC 5545 §3.1. Most clients cope with over-long lines; some Outlook versions
  # truncate at the limit instead.
  test "folds content lines at 75 octets" do
    lines = Wedding.to_ics.split("\r\n")

    assert lines.all? { |line| line.bytesize <= 75 }, "unfolded: #{lines.select { |l| l.bytesize > 75 }}"
    assert_includes lines.map { |line| line[0] }, " ", "expected at least one continuation line"
  end

  # The description carries an em dash, and folding by byte count without respecting
  # character boundaries would split it down the middle.
  test "folds on character boundaries, not mid-codepoint" do
    assert Wedding.to_ics.valid_encoding?
    assert_includes Wedding.to_ics.delete("\r\n "), "—"
  end

  test "escapes the reserved characters in text values" do
    # The address has commas in it, so this is not academic.
    assert_match(/^LOCATION:.*\\,/, Wedding.to_ics)

    assert_equal "a\\\\b", Wedding.escape_ics("a\\b")
    assert_equal "a\\;b", Wedding.escape_ics("a;b")
    assert_equal "a\\nb", Wedding.escape_ics("a\nb")
  end

  test "hands Google Calendar the zone rather than a shifted wall clock" do
    url = Wedding.google_calendar_url

    assert_includes url, "ctz=America%2FToronto"
    assert_includes url, "dates=#{Wedding.ical_stamp(Wedding::STARTS_AT)}"
  end
end
