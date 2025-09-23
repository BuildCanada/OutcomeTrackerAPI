# frozen_string_literal: true
require "digest/md5"
require "stringio"
require "securerandom"

module Lake
  class Writer
    # rows: Array<Hash>; dest_prefix: e.g., "statcan"; partition_dt: Date or "YYYY-MM-DD"
    def self.write_jsonl(rows:, dest_prefix:, partition_dt: Date.today)
      return if rows.blank?

      dt   = partition_dt.is_a?(Date) ? partition_dt.strftime("%Y-%m-%d") : partition_dt.to_s
      body = rows.map { |r| JSON.generate(r) }.join("\n") + "\n"
      key  = "silver/#{dest_prefix}/dt=#{dt}/part-#{SecureRandom.uuid}.jsonl"

      LAKE_STORAGE.upload(
        key,
        StringIO.new(body),
        checksum: Digest::MD5.base64digest(body),
        content_type: "application/x-ndjson",
        disposition: :inline
      )
      key
    end
  end
end
