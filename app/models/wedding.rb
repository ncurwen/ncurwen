# The event itself, in one place.
#
# PLACEHOLDER VALUES — the date, venue and address are stand-ins. Everything on the
# invitation that depends on *when* and *where* reads from here (the hero copy, the
# countdown, the map link, the calendar file), so replacing them is a single edit to
# this file rather than a hunt through the view.
#
# Not an ActiveRecord model; it lives in app/models because it's domain vocabulary,
# and there is exactly one wedding.
module Wedding
  # The venue's zone, not the server's. A guest in another timezone should still see
  # "282 days to go" counting down to the party's local Saturday, and the calendar
  # file has to name a zone rather than pin an instant.
  ZONE = ActiveSupport::TimeZone["America/Toronto"]

  STARTS_AT = ZONE.local(2027, 6, 12, 17, 0)
  ENDS_AT   = ZONE.local(2027, 6, 12, 23, 59)

  VENUE   = "Placeholder Hall"
  ADDRESS = "000 Placeholder Avenue, London, ON"

  TITLE       = "Alex & Nick's Party"
  DESCRIPTION = "The celebration. We're eloping for the \"I do\" — this is the good part."

  # Whole days between today and the party, both read in the venue's zone so the
  # number ticks over at midnight *there*. Clamped at zero: on the day itself, and
  # ever after, the answer is 0 rather than a negative.
  def self.days_away(to: STARTS_AT, from: Time.current)
    [ (to.in_time_zone(ZONE).to_date - from.in_time_zone(ZONE).to_date).to_i, 0 ].max
  end

  def self.map_url
    "https://www.google.com/maps/search/?api=1&query=#{CGI.escape("#{VENUE}, #{ADDRESS}")}"
  end

  # The "Add to Google Calendar" template URL. Times are UTC instants here (the `Z`
  # suffix), which is what this endpoint expects.
  def self.google_calendar_url
    params = {
      action: "TEMPLATE",
      text: TITLE,
      dates: "#{ical_stamp(STARTS_AT)}/#{ical_stamp(ENDS_AT)}",
      details: DESCRIPTION,
      location: "#{VENUE}, #{ADDRESS}",
      ctz: ZONE.tzinfo.name
    }
    "https://calendar.google.com/calendar/render?#{params.to_query}"
  end

  # `20270612T170000` — the local wall-clock form, paired with `ctz` in the Google URL
  # so the reader's own timezone doesn't shift the party.
  def self.ical_stamp(time) = time.strftime("%Y%m%dT%H%M%S")

  # The .ics body, as a single CRLF-delimited string.
  #
  # UTC instants (the `Z` suffix) rather than a TZID: naming a zone obliges us to ship
  # a matching VTIMEZONE block, and strict clients reject the file without one. The
  # party is at one moment in time, so an instant loses nothing.
  def self.to_ics(uid: "wedding-#{ical_stamp(STARTS_AT)}@ncurwen.com")
    [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//ncurwen//wedding//EN",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "BEGIN:VEVENT",
      "UID:#{uid}",
      "DTSTAMP:#{utc_stamp(Time.current)}",
      "DTSTART:#{utc_stamp(STARTS_AT)}",
      "DTEND:#{utc_stamp(ENDS_AT)}",
      "SUMMARY:#{escape_ics(TITLE)}",
      "DESCRIPTION:#{escape_ics(DESCRIPTION)}",
      "LOCATION:#{escape_ics("#{VENUE}, #{ADDRESS}")}",
      "END:VEVENT",
      "END:VCALENDAR"
    ].map { |line| fold_ics(line) }.join("\r\n") + "\r\n"
  end

  def self.utc_stamp(time) = time.utc.strftime("%Y%m%dT%H%M%SZ")

  # RFC 5545 §3.1: content lines are limited to 75 octets, continued by a CRLF and a
  # single leading space. Our description is over that, and while most clients cope,
  # some Outlook versions truncate at the limit instead.
  #
  # Measured in bytes but split on character boundaries — the description has an em
  # dash in it, and folding mid-codepoint would corrupt it.
  MAX_ICS_OCTETS = 75

  def self.fold_ics(line)
    return line if line.bytesize <= MAX_ICS_OCTETS

    lines = [ +"" ]
    limit = MAX_ICS_OCTETS

    line.each_char do |char|
      # Continuation lines spend one octet on their leading space.
      if lines.last.bytesize + char.bytesize > limit
        lines << +" "
        limit = MAX_ICS_OCTETS
      end
      lines.last << char
    end

    lines.join("\r\n")
  end

  # RFC 5545 §3.3.11: backslash, semicolon, comma and newline are the reserved
  # characters in a TEXT value. Our address has commas in it, so this is not academic.
  def self.escape_ics(text)
    # Block form deliberately: in gsub's *replacement string* a backslash is itself an
    # escape character, so the obvious `gsub("\\", "\\\\")` silently yields a single
    # backslash. A block's return value is taken literally. One pass over a character
    # class, so an escaped backslash isn't escaped again by a later gsub.
    text.gsub(/[\\;,\n]/) { |char| char == "\n" ? "\\n" : "\\#{char}" }
  end
end
