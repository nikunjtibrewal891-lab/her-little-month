-- HER LITTLE MONTH database patch
-- Run once in Supabase SQL Editor after the original schema.

alter table public.couples
  add column if not exists invite_code text unique;

update public.couples
set invite_code = lower(substr(replace(gen_random_uuid()::text,'-',''),1,10))
where invite_code is null;

insert into public.plans (couple_id, plan_date, is_open, title, note)
select c.id, d::date,
       (extract(day from d)::int between 7 and 13),
       'Today''s little things',
       'Today is not about doing everything perfectly. Just give yourself one quiet hour.'
from public.couples c
cross join generate_series(date '2026-10-01', date '2026-10-31', interval '1 day') d
on conflict (couple_id, plan_date) do nothing;

insert into public.activities(plan_id,title,description,duration_minutes,icon,sort_order)
select p.id,v.title,v.description,v.minutes,v.icon,v.ord
from public.plans p
join (values
(date '2026-10-07','30-min full-body stretching','5 min gentle warm-up; 5 min neck & shoulders; 5 min upper back & chest; 5 min hips; 5 min hamstrings, quads & calves; 5 min relaxed full-body finish. Never force a stretch.',30,'🧘‍♀️',1),
(date '2026-10-07','Guided grounding meditation','Notice your breath, body and surroundings.',15,'🌿',2),
(date '2026-10-07','Journal · What am I feeling right now?','Name the feeling, where you feel it, and what you might need.',15,'📓',3),
(date '2026-10-08','30-min full-body stretching','5 min gentle warm-up; 5 min neck & shoulders; 5 min upper back & chest; 5 min hips; 5 min hamstrings, quads & calves; 5 min relaxed full-body finish. Never force a stretch.',30,'🧘‍♀️',1),
(date '2026-10-08','Guided breathing meditation','Return attention to slow, comfortable breathing.',15,'🌿',2),
(date '2026-10-08','Journal · What triggered me today?','What happened? What did I feel? What did I want to do? What could I choose next time?',15,'📓',3),
(date '2026-10-09','30-min full-body stretching','5 min gentle warm-up; 5 min neck & shoulders; 5 min upper back & chest; 5 min hips; 5 min hamstrings, quads & calves; 5 min relaxed full-body finish. Never force a stretch.',30,'🧘‍♀️',1),
(date '2026-10-09','Guided anxiety-soothing meditation','Ground in the present moment and surroundings.',15,'🌿',2),
(date '2026-10-09','Journal · What is within my control?','Separate what you can influence from what you cannot control today.',15,'📓',3),
(date '2026-10-10','30-min full-body stretching','5 min gentle warm-up; 5 min neck & shoulders; 5 min upper back & chest; 5 min hips; 5 min hamstrings, quads & calves; 5 min relaxed full-body finish. Never force a stretch.',30,'🧘‍♀️',1),
(date '2026-10-10','Guided emotional regulation meditation','Notice sensations without judging them.',15,'🌿',2),
(date '2026-10-10','Journal · What is my anger trying to protect?','Look beneath the reaction: hurt, fear, unfairness, exhaustion, boundary or need.',15,'📓',3),
(date '2026-10-11','30-min full-body stretching','5 min gentle warm-up; 5 min neck & shoulders; 5 min upper back & chest; 5 min hips; 5 min hamstrings, quads & calves; 5 min relaxed full-body finish. Never force a stretch.',30,'🧘‍♀️',1),
(date '2026-10-11','Guided self-compassion meditation','Offer yourself patience rather than pressure.',15,'🌿',2),
(date '2026-10-11','Journal · How would I speak to someone I love?','Write the advice, reassurance or kindness you would give them—and give some of it to yourself.',15,'📓',3),
(date '2026-10-12','30-min full-body stretching','5 min gentle warm-up; 5 min neck & shoulders; 5 min upper back & chest; 5 min hips; 5 min hamstrings, quads & calves; 5 min relaxed full-body finish. Never force a stretch.',30,'🧘‍♀️',1),
(date '2026-10-12','Guided acceptance meditation','Notice what is present without forcing it away.',15,'🌿',2),
(date '2026-10-12','Journal · What am I fighting that I cannot change?','What would change if you stopped spending energy arguing with the fact that it happened?',15,'📓',3),
(date '2026-10-13','30-min full-body stretching','5 min gentle warm-up; 5 min neck & shoulders; 5 min upper back & chest; 5 min hips; 5 min hamstrings, quads & calves; 5 min relaxed full-body finish. Never force a stretch.',30,'🧘‍♀️',1),
(date '2026-10-13','Guided calm-body meditation','Slow down and notice what feels different.',15,'🌿',2),
(date '2026-10-13','Journal · What did I learn about myself?','What helped? What felt difficult? What would you like more of next week?',15,'📓',3)
) as v(plan_date,title,description,minutes,icon,ord) on p.plan_date=v.plan_date
where p.plan_date between date '2026-10-07' and date '2026-10-13';

create policy "First authenticated user can claim owner"
on public.couple_members
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and role = 'owner'
  and not exists (select 1 from public.couple_members)
);

create or replace function public.claim_owner()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare cid uuid;
begin
  if exists (select 1 from public.couple_members) then return false; end if;
  select id into cid from public.couples order by created_at limit 1;
  if cid is null then raise exception 'No Her Little Month space exists'; end if;
  insert into public.couple_members(couple_id,user_id,role)
  values(cid,(select auth.uid()),'owner')
  on conflict do nothing;
  return true;
end;
$$;

revoke all on function public.claim_owner() from public;
grant execute on function public.claim_owner() to authenticated;

create policy "Owner can update couple"
on public.couples
for update to authenticated
using (public.is_couple_owner(id))
with check (public.is_couple_owner(id));

create or replace function public.join_couple(p_code text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare cid uuid;
begin
  select id into cid from public.couples
  where invite_code = lower(trim(p_code)) limit 1;
  if cid is null then raise exception 'Invalid invite code'; end if;
  insert into public.couple_members(couple_id,user_id,role)
  values(cid,(select auth.uid()),'partner')
  on conflict do nothing;
  return true;
end;
$$;

revoke all on function public.join_couple(text) from public;
grant execute on function public.join_couple(text) to authenticated;

grant select,insert,update,delete on public.couples,public.couple_members,
  public.plans,public.activities,public.activity_completions,
  public.journal_entries,public.messages to authenticated;
