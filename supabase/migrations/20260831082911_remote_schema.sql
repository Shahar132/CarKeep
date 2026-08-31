SET local check_function_bodies = off;

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON SEQUENCES FROM "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON SEQUENCES FROM "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON SEQUENCES FROM "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON FUNCTIONS FROM "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON FUNCTIONS FROM "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON FUNCTIONS FROM "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON TABLES FROM "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON TABLES FROM "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON TABLES FROM "service_role";

CREATE TABLE "public"."documents" (
  "id"                 uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "vehicle_id"         uuid                     NOT NULL,
  "event_id"           uuid,
  "display_name"       text                     NOT NULL,
  "original_file_name" text,
  "file_path"          text                     NOT NULL,
  "uploaded_by"        uuid,
  "created_at"         timestamp with time zone NOT NULL DEFAULT now(),
  "category"           text                     NOT NULL DEFAULT 'other'::text,
  CONSTRAINT "documents_category_check" CHECK ((category = ANY (ARRAY['vehicle_license'::text, 'test'::text, 'insurance'::text, 'service'::text, 'other'::text]))),
  CONSTRAINT "documents_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."documents"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."profiles" (
  "id"         uuid                     NOT NULL,
  "name"       text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "profiles_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."profiles"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."vehicle_events" (
  "id"                  uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "vehicle_id"          uuid                     NOT NULL,
  "type"                text                     NOT NULL,
  "title"               text                     NOT NULL,
  "event_date"          date                     NOT NULL,
  "mileage"             integer,
  "cost"                numeric(10,2),
  "notes"               text,
  "insurance_type"      text,
  "created_by"          uuid,
  "created_at"          timestamp with time zone NOT NULL DEFAULT now(),
  "service_interval_km" integer,
  CONSTRAINT "vehicle_events_cost_check" CHECK (((cost IS NULL) OR (cost >= (0)::numeric))),
  CONSTRAINT "vehicle_events_insurance_type_check"
    CHECK (((insurance_type IS NULL) OR (insurance_type = ANY (ARRAY['mandatory'::text, 'comprehensive'::text, 'third_party'::text])))),
  CONSTRAINT "vehicle_events_mileage_check" CHECK (((mileage IS NULL) OR (mileage >= 0))),
  CONSTRAINT "vehicle_events_pkey" PRIMARY KEY (id),
  CONSTRAINT "vehicle_events_service_interval_km_check" CHECK (((service_interval_km IS NULL) OR (service_interval_km > 0))),
  CONSTRAINT "vehicle_events_type_check" CHECK ((type = ANY (ARRAY['service'::text, 'test'::text, 'vehicle_license'::text, 'insurance'::text, 'repair'::text, 'other'::text])))
);

ALTER TABLE "public"."vehicle_events"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."vehicle_insurances" (
  "id"           uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "vehicle_id"   uuid                     NOT NULL,
  "type"         text                     NOT NULL,
  "expiry_date"  date,
  "show_on_home" boolean                  NOT NULL DEFAULT false,
  "created_at"   timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"   timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "vehicle_insurances_pkey" PRIMARY KEY (id),
  CONSTRAINT "vehicle_insurances_type_check" CHECK ((type = ANY (ARRAY['mandatory'::text, 'comprehensive'::text, 'third_party'::text]))),
  CONSTRAINT "vehicle_insurances_vehicle_id_type_key" UNIQUE (vehicle_id, TYPE)
);

ALTER TABLE "public"."vehicle_insurances"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."vehicle_members" (
  "vehicle_id" uuid                     NOT NULL,
  "user_id"    uuid                     NOT NULL,
  "role"       text                     NOT NULL DEFAULT 'member'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "vehicle_members_pkey" PRIMARY KEY (vehicle_id, user_id),
  CONSTRAINT "vehicle_members_role_check" CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text])))
);

ALTER TABLE "public"."vehicle_members"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."vehicles" (
  "id"                           uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "license"                      text                     NOT NULL,
  "manufacturer"                 text                     NOT NULL,
  "model"                        text                     NOT NULL,
  "year"                         integer                  NOT NULL,
  "mileage"                      integer                  NOT NULL,
  "test_expiry_date"             date,
  "last_service_date"            date,
  "last_service_mileage"         integer,
  "service_interval_km"          integer,
  "created_at"                   timestamp with time zone NOT NULL DEFAULT now(),
  "show_test_on_home"            boolean                  NOT NULL DEFAULT true,
  "show_service_on_home"         boolean                  NOT NULL DEFAULT true,
  "vehicle_license_expiry_date"  date,
  "show_vehicle_license_on_home" boolean                  NOT NULL DEFAULT false,
  CONSTRAINT "vehicles_last_service_mileage_check" CHECK (((last_service_mileage IS NULL) OR (last_service_mileage >= 0))),
  CONSTRAINT "vehicles_license_key" UNIQUE (license),
  CONSTRAINT "vehicles_mileage_check" CHECK ((mileage >= 0)),
  CONSTRAINT "vehicles_pkey" PRIMARY KEY (id),
  CONSTRAINT "vehicles_service_interval_km_check" CHECK (((service_interval_km IS NULL) OR (service_interval_km > 0)))
);

ALTER TABLE "public"."vehicles"
  ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.add_vehicle_member_by_email (
  target_vehicle_id uuid,
  member_email      text
)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  target_user_id uuid;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  -- Only the vehicle owner may add members.
  if not public.is_vehicle_owner(target_vehicle_id) then
    raise exception 'OWNER_REQUIRED';
  end if;

  if member_email is null
     or btrim(member_email) = '' then
    raise exception 'INVALID_EMAIL';
  end if;

  -- Find an existing Supabase Auth user.
  select au.id
  into target_user_id
  from auth.users au
  where lower(au.email) =
        lower(btrim(member_email))
  limit 1;

  if target_user_id is null then
    raise exception 'USER_NOT_FOUND';
  end if;

  -- The owner is already connected to the vehicle.
  if target_user_id = auth.uid() then
    raise exception 'CANNOT_ADD_SELF';
  end if;

  if exists (
    select 1
    from public.vehicle_members vm
    where vm.vehicle_id = target_vehicle_id
      and vm.user_id = target_user_id
  ) then
    raise exception 'ALREADY_MEMBER';
  end if;

  -- New people always start as regular members.
  insert into public.vehicle_members (
    vehicle_id,
    user_id,
    role
  )
  values (
    target_vehicle_id,
    target_user_id,
    'member'
  );

exception
  when unique_violation then
    raise exception 'ALREADY_MEMBER';
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_vehicle_members_for_owner (
  target_vehicle_id uuid
)
  RETURNS TABLE (
    user_id uuid,
    name    text,
    email   text,
    role    text
  )
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  -- Only the owner may see the full member list.
  if not public.is_vehicle_owner(target_vehicle_id) then
    raise exception 'OWNER_REQUIRED';
  end if;

  return query
  select
    vm.user_id,
    coalesce(p.name, '')::text as name,
    coalesce(au.email, '')::text as email,
    vm.role::text as role
  from public.vehicle_members vm
  left join public.profiles p
    on p.id = vm.user_id
  left join auth.users au
    on au.id = vm.user_id
  where vm.vehicle_id = target_vehicle_id
  order by
    case vm.role
      when 'owner' then 1
      when 'admin' then 2
      when 'member' then 3
      else 4
    end,
    coalesce(p.name, au.email, '');
end;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
begin
  insert into public.profiles (
    id,
    name
  )
  values (
    new.id,
    new.raw_user_meta_data ->> 'name'
  )
  on conflict (id)
  do update set
    name = excluded.name;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_vehicle_owner()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
begin
  if auth.uid() is not null then
    insert into public.vehicle_members (
      vehicle_id,
      user_id,
      role
    )
    values (
      new.id,
      auth.uid(),
      'owner'
    );
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.handle_user_account_deletion()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
begin
  -- ----------------------------------------------------------
  -- Block account deletion if the user owns a shared vehicle.
  -- Ownership must be transferred first.
  -- ----------------------------------------------------------

  if exists (
    select 1
    from public.vehicle_members owner_membership
    where owner_membership.user_id = old.id
      and owner_membership.role = 'owner'
      and exists (
        select 1
        from public.vehicle_members other_member
        where other_member.vehicle_id =
              owner_membership.vehicle_id
          and other_member.user_id <> old.id
      )
  ) then
    raise exception
      'OWNERSHIP_TRANSFER_REQUIRED';
  end if;


  -- ----------------------------------------------------------
  -- Delete vehicles where this user is the owner
  -- and there are no other members.
  --
  -- Because vehicle-related tables use ON DELETE CASCADE,
  -- their history, insurances, memberships, etc. are removed.
  -- ----------------------------------------------------------

  delete from public.vehicles vehicle
  using public.vehicle_members owner_membership
  where owner_membership.vehicle_id = vehicle.id
    and owner_membership.user_id = old.id
    and owner_membership.role = 'owner'
    and not exists (
      select 1
      from public.vehicle_members other_member
      where other_member.vehicle_id = vehicle.id
        and other_member.user_id <> old.id
    );


  return old;
end;
$function$;

CREATE OR REPLACE FUNCTION public.is_vehicle_manager (
  target_vehicle_id uuid
)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
  select exists (
    select 1
    from public.vehicle_members
    where vehicle_id = target_vehicle_id
      and user_id = auth.uid()
      and role in ('owner', 'admin')
  );
$function$;

CREATE OR REPLACE FUNCTION public.is_vehicle_member (
  target_vehicle_id uuid
)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select exists (
    select 1
    from public.vehicle_members
    where vehicle_id = target_vehicle_id
      and user_id = auth.uid()
  );
$function$;

CREATE OR REPLACE FUNCTION public.is_vehicle_owner (
  target_vehicle_id uuid
)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select exists (
    select 1
    from public.vehicle_members
    where vehicle_id = target_vehicle_id
      and user_id = auth.uid()
      and role = 'owner'
  );
$function$;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
  RETURNS event_trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.transfer_vehicle_ownership (
  target_vehicle_id uuid,
  new_owner_user_id uuid
)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  current_user_id uuid;
  new_owner_role text;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'User is not authenticated';
  end if;

  -- Only the current owner can transfer ownership.
  if not public.is_vehicle_owner(target_vehicle_id) then
    raise exception 'Only the vehicle owner can transfer ownership';
  end if;

  -- Cannot transfer ownership to yourself.
  if new_owner_user_id = current_user_id then
    raise exception 'User is already the vehicle owner';
  end if;

  -- Lock the vehicle memberships while ownership is transferred.
  perform 1
  from public.vehicle_members
  where vehicle_id = target_vehicle_id
  for update;

  -- The new owner must already belong to the vehicle.
  select role
  into new_owner_role
  from public.vehicle_members
  where vehicle_id = target_vehicle_id
    and user_id = new_owner_user_id;

  if new_owner_role is null then
    raise exception 'New owner must already be a vehicle member';
  end if;

  if new_owner_role not in ('admin', 'member') then
    raise exception 'Invalid new owner role';
  end if;

  -- Previous owner becomes admin.
  update public.vehicle_members
  set role = 'admin'
  where vehicle_id = target_vehicle_id
    and user_id = current_user_id
    and role = 'owner';

  -- Selected member becomes the new owner.
  update public.vehicle_members
  set role = 'owner'
  where vehicle_id = target_vehicle_id
    and user_id = new_owner_user_id;
end;
$function$;

ALTER TABLE "public"."documents"
  ADD CONSTRAINT "documents_uploaded_by_fkey" FOREIGN KEY (uploaded_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE "public"."profiles"
  ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."vehicle_events"
  ADD CONSTRAINT "vehicle_events_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE "public"."documents"
  ADD CONSTRAINT "documents_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.vehicle_events(id) ON DELETE SET NULL;

ALTER TABLE "public"."vehicle_members"
  ADD CONSTRAINT "vehicle_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."documents"
  ADD CONSTRAINT "documents_vehicle_id_fkey" FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;

ALTER TABLE "public"."vehicle_events"
  ADD CONSTRAINT "vehicle_events_vehicle_id_fkey" FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;

ALTER TABLE "public"."vehicle_insurances"
  ADD CONSTRAINT "vehicle_insurances_vehicle_id_fkey" FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;

ALTER TABLE "public"."vehicle_members"
  ADD CONSTRAINT "vehicle_members_vehicle_id_fkey" FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;

CREATE INDEX documents_vehicle_category_idx ON public.documents USING btree (vehicle_id, category);

CREATE INDEX documents_vehicle_id_idx ON public.documents USING btree (vehicle_id);

CREATE INDEX vehicle_events_type_idx ON public.vehicle_events USING btree (vehicle_id, TYPE);

CREATE INDEX vehicle_events_vehicle_id_idx ON public.vehicle_events USING btree (vehicle_id);

CREATE INDEX vehicle_insurances_vehicle_id_idx ON public.vehicle_insurances USING btree (vehicle_id);

CREATE UNIQUE INDEX vehicle_members_one_owner_per_vehicle_idx ON public.vehicle_members USING btree (vehicle_id)
  WHERE (ROLE = 'owner'::text);

CREATE INDEX vehicle_members_user_id_idx ON public.vehicle_members USING btree (user_id);

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_auth_user_delete_vehicle_cleanup
  BEFORE DELETE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_user_account_deletion();

CREATE TRIGGER on_vehicle_created
  AFTER INSERT ON public.vehicles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_vehicle_owner();

CREATE POLICY "vehicle managers can create documents" ON "public"."documents"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.is_vehicle_manager(vehicle_id));

CREATE POLICY "vehicle managers can delete documents" ON "public"."documents"
  FOR DELETE
  TO "authenticated"
  USING (public.is_vehicle_manager(vehicle_id));

CREATE POLICY "vehicle managers can update documents" ON "public"."documents"
  FOR UPDATE
  TO "authenticated"
  USING (public.is_vehicle_manager(vehicle_id))
  WITH CHECK (public.is_vehicle_manager(vehicle_id));

CREATE POLICY "vehicle members can view documents" ON "public"."documents"
  FOR SELECT
  TO "authenticated"
  USING (public.is_vehicle_member(vehicle_id));

CREATE POLICY "Users can update own profile" ON "public"."profiles"
  FOR UPDATE
  TO "authenticated"
  USING ((id = auth.uid()))
  WITH CHECK ((id = auth.uid()));

CREATE POLICY "Users can view own profile" ON "public"."profiles"
  FOR SELECT
  TO "authenticated"
  USING ((id = auth.uid()));

CREATE POLICY "vehicle managers can create events" ON "public"."vehicle_events"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.is_vehicle_manager(vehicle_id));

CREATE POLICY "vehicle managers can delete events" ON "public"."vehicle_events"
  FOR DELETE
  TO "authenticated"
  USING (public.is_vehicle_manager(vehicle_id));

CREATE POLICY "vehicle members can view events" ON "public"."vehicle_events"
  FOR SELECT
  TO "authenticated"
  USING (public.is_vehicle_member(vehicle_id));

CREATE POLICY "vehicle managers can create insurances" ON "public"."vehicle_insurances"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.is_vehicle_manager(vehicle_id));

CREATE POLICY "vehicle managers can delete insurances" ON "public"."vehicle_insurances"
  FOR DELETE
  TO "authenticated"
  USING (public.is_vehicle_manager(vehicle_id));

CREATE POLICY "vehicle managers can update insurances" ON "public"."vehicle_insurances"
  FOR UPDATE
  TO "authenticated"
  USING (public.is_vehicle_manager(vehicle_id))
  WITH CHECK (public.is_vehicle_manager(vehicle_id));

CREATE POLICY "vehicle members can view insurances" ON "public"."vehicle_insurances"
  FOR SELECT
  TO "authenticated"
  USING (public.is_vehicle_member(vehicle_id));

CREATE POLICY "users can view relevant vehicle memberships" ON "public"."vehicle_members"
  FOR SELECT
  TO "authenticated"
  USING (((user_id = auth.uid()) OR public.is_vehicle_owner(vehicle_id)));

CREATE POLICY "vehicle members can leave or owner can remove members" ON "public"."vehicle_members"
  FOR DELETE
  TO "authenticated"
  USING (((ROLE <> 'owner'::text) AND ((user_id = auth.uid()) OR public.is_vehicle_owner(vehicle_id))));

CREATE POLICY "vehicle owner can add members" ON "public"."vehicle_members"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.is_vehicle_owner(vehicle_id));

CREATE POLICY "vehicle owner can update non owner members" ON "public"."vehicle_members"
  FOR UPDATE
  TO "authenticated"
  USING ((public.is_vehicle_owner(vehicle_id) AND (ROLE <> 'owner'::text)))
  WITH CHECK ((public.is_vehicle_owner(vehicle_id) AND (role <> 'owner'::text)));

CREATE POLICY "authenticated users can create vehicles" ON "public"."vehicles"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((auth.uid() IS NOT NULL));

CREATE POLICY "vehicle managers can update vehicles" ON "public"."vehicles"
  FOR UPDATE
  TO "authenticated"
  USING (public.is_vehicle_manager(id))
  WITH CHECK (public.is_vehicle_manager(id));

CREATE POLICY "vehicle members can view vehicles" ON "public"."vehicles"
  FOR SELECT
  TO "authenticated"
  USING (public.is_vehicle_member(id));

CREATE POLICY "vehicle owner can delete vehicle" ON "public"."vehicles"
  FOR DELETE
  TO "authenticated"
  USING (public.is_vehicle_owner(id));

CREATE POLICY "vehicle managers can delete document files" ON "storage"."objects"
  FOR DELETE
  TO "authenticated"
  USING (((bucket_id = 'vehicle-documents'::text) AND public.is_vehicle_manager((split_part(name, '/'::text, 1))::uuid)));

CREATE POLICY "vehicle managers can update document files" ON "storage"."objects"
  FOR UPDATE
  TO "authenticated"
  USING (((bucket_id = 'vehicle-documents'::text) AND public.is_vehicle_manager((split_part(name, '/'::text, 1))::uuid)))
  WITH CHECK (((bucket_id = 'vehicle-documents'::text) AND public.is_vehicle_manager((split_part(name, '/'::text, 1))::uuid)));

CREATE POLICY "vehicle managers can upload document files" ON "storage"."objects"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (((bucket_id = 'vehicle-documents'::text) AND public.is_vehicle_manager((split_part(name, '/'::text, 1))::uuid)));

CREATE POLICY "vehicle members can view document files" ON "storage"."objects"
  FOR SELECT
  TO "authenticated"
  USING (((bucket_id = 'vehicle-documents'::text) AND public.is_vehicle_member((split_part(name, '/'::text, 1))::uuid)));

CREATE EVENT TRIGGER "ensure_rls"
  ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
  EXECUTE FUNCTION "public"."rls_auto_enable"();

REVOKE ALL ON FUNCTION "public"."add_vehicle_member_by_email"(uuid, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."add_vehicle_member_by_email"(uuid, text) TO "authenticated", "postgres";

REVOKE ALL ON FUNCTION "public"."get_vehicle_members_for_owner"(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."get_vehicle_members_for_owner"(uuid) TO "authenticated", "postgres";

GRANT EXECUTE ON FUNCTION "public"."handle_new_user"() TO PUBLIC, "postgres";

GRANT EXECUTE ON FUNCTION "public"."handle_new_vehicle_owner"() TO PUBLIC, "postgres";

GRANT EXECUTE ON FUNCTION "public"."handle_user_account_deletion"() TO PUBLIC, "postgres";

GRANT EXECUTE ON FUNCTION "public"."is_vehicle_manager"(uuid) TO PUBLIC, "postgres";

GRANT EXECUTE ON FUNCTION "public"."is_vehicle_member"(uuid) TO PUBLIC, "postgres";

GRANT EXECUTE ON FUNCTION "public"."is_vehicle_owner"(uuid) TO PUBLIC, "postgres";

GRANT EXECUTE ON FUNCTION "public"."rls_auto_enable"() TO PUBLIC, "postgres";

REVOKE ALL ON FUNCTION "public"."transfer_vehicle_ownership"(uuid, uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."transfer_vehicle_ownership"(uuid, uuid) TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."documents" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."documents" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."documents" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."profiles" TO "anon";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."profiles" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."profiles" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."profiles" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."vehicle_events" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vehicle_events" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."vehicle_events" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."vehicle_insurances" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vehicle_insurances" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."vehicle_insurances" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."vehicle_members" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vehicle_members" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."vehicle_members" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."vehicles" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."vehicles" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."vehicles" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES TO "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES TO "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES TO "service_role";

