module RecordTimeline
  private
    def load_record_timeline(on: Date.current)
      records = set_page_and_extract_portion_from(
        @budget.records.where(occurred_on: ..on),
        ordered_by: { occurred_on: :desc, created_at: :desc, id: :desc }
      )
      @timeline = RecentRecords.new.snapshot(budget: @budget, records:, on:)
    end
end
