function organizer(o: any) {
  return o ? { id: o.id, display_name: o.displayName, username: o.username, photo_url: o.photoUrl } : null;
}

export function toCard(t: any) {
  return {
    id: t.id,
    title: t.title,
    cover_url: t.coverUrl,
    schedule_type: t.scheduleType,
    num_days: t.numDays,
    pigeon_count: t.pigeonCount,
    status: t.status,
    like_count: t.likeCount,
    view_count: t.viewCount,
    follower_count: t.followerCount,
    link_slug: t.linkSlug,
    organizer: organizer(t.organizer),
    created_at: t.createdAt.toISOString(),
  };
}

export function toDetail(t: any) {
  return {
    ...toCard(t),
    rules: t.rules,
    description: t.description,
    organizer_contact: t.organizerContact,
    overall_avg_seconds: t.overallAvgSeconds,
    days: (t.days ?? []).map((d: any) => ({
      id: d.id,
      day_number: d.dayNumber,
      date: d.date.toISOString().slice(0, 10),
    })),
  };
}

export function toParticipantRow(p: any) {
  return {
    id: p.id,
    name: p.name,
    photo_url: p.photoUrl,
    position: p.position,
    overall_avg_seconds: p.overallAvgSeconds,
    overall_returned_count: p.overallReturnedCount,
  };
}

export function toParticipantDetail(data: any) {
  const p = data.participant;
  return {
    participant: {
      id: p.id,
      name: p.name,
      photo_url: p.photoUrl,
      contact_no: p.contactNo,
      phone: p.phone,
      address: p.address,
      position: p.position,
      overall_avg_seconds: p.overallAvgSeconds,
      overall_returned_count: p.overallReturnedCount,
    },
    days: data.days.map((d: any) => ({
      day_id: d.id,
      day_number: d.dayNumber,
      date: d.date.toISOString().slice(0, 10),
      avg_seconds: d.stats?.[0]?.avgSeconds ?? null,
      returned_count: d.stats?.[0]?.returnedCount ?? 0,
      flights: d.flights.map((f: any) => ({
        id: f.id,
        pigeon_name: f.pigeonName,
        landing_time: f.landingTime.toISOString(),
        duration_seconds: f.durationSeconds,
      })),
    })),
  };
}

export function toFlight(f: any) {
  return {
    id: f.id,
    participant_id: f.participantId,
    day_id: f.dayId,
    pigeon_name: f.pigeonName,
    landing_time: f.landingTime.toISOString(),
    duration_seconds: f.durationSeconds,
  };
}
