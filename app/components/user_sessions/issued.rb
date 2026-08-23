# frozen_string_literal: true

# Value object returned by UserSessions::Creator — the session row plus the
# signed JWT the client presents on subsequent requests.
module UserSessions
  Issued = Data.define(:session, :token)
end
