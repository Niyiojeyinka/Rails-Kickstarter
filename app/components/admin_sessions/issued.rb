# frozen_string_literal: true

# Value object returned by AdminSessions::Creator. The raw token exists only
# here — only its digest is persisted, so it cannot be recovered later.
module AdminSessions
  Issued = Data.define(:session, :raw_token)
end
