-- The delete-account Edge Function uses a service-role Supabase client
-- to inspect account ownership and document paths before deleting a user.
--
-- Grant only the read permissions required by that function.

GRANT SELECT
ON TABLE public.vehicle_members
TO service_role;

GRANT SELECT
ON TABLE public.documents
TO service_role;