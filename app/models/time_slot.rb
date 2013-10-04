class TimeSlot < ActiveRecord::Base

  # SCOPES

  scope :upcoming, lambda { where("start_at > ?", Time.now) }
  scope :expired,  lambda { where("finish_at < ?", Time.now) }
  scope :current,  lambda { where("(start_at < ?) AND (finish_at > ?)", Time.now, Time.now) }
  scope :current_or_upcoming, lambda { where("finish_at >= ?", Time.now) }

  # ASSOCIATIONS

  belongs_to :vendor
  belongs_to :location

  # VALIDATIONS

  validate :has_no_time_conflicts

  # ATTRIBUTES
 
  attr_accessible :location_id, :vendor_id, :start_at, :finish_at

  # CLASS METHODS

  def self.by_scope(scope_name)
    scope_name ||= :current_or_upcoming
    respond_to?(scope_name) ? send(scope_name) : all
  end

  # INSTANCE METHODS

  def to_s
    "#{id}"
  end

  def available?
    vendor.nil?
  end

  def conflicts_with?(time_slot)
    [:start_at, :finish_at].any? do |method|
      has_time?(time_slot.send(method)) || time_slot.has_time?(send(method))
    end
  end

  def has_time?(time)
    time > start_at && time < finish_at
  end

  def to_ical_event
    Icalendar::Event.new.tap do |event|
      event.start       = ical_time(start_at)
      event.end         = ical_time(finish_at)
      event.summary     = "#{vendor.name} at #{location.name}"
      event.description = "#{vendor.name} - #{vendor.cuisine}"
    end
  end

  private

  def ical_time(t)
    DateTime.civil(t.year, t.month, t.day, t.hour, t.min)
  end

  def has_time_conflict?
    location.time_slots.where("id != ?", id).any? {|time_slot| conflicts_with?(time_slot) }
  end

  def has_no_time_conflicts
    if has_time_conflict?
      errors.add(:base, "Time slot conflicts with existing time slot")
    end
  end

end
