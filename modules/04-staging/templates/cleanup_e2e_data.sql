-- Release Conveyor Kit - module 04-staging (variant B)
-- E2E/QA test data cleanup RPC. Origin: proven donor migration
-- (20260326020000_e2e_cleanup_rpc.sql), generalized.
--
-- Why an RPC: Playwright cleanup hooks must NOT hold a service role key.
-- This function is called with the QA user's own JWT (anon key + Bearer) and
-- only ever deletes rows owned by auth.uid() - no blast radius beyond the
-- calling user.
--
-- ADAPT to your schema: replace tasks/created_by/title and the optional
-- second block with your tables. Keep the auth.uid() ownership guard.

CREATE OR REPLACE FUNCTION cleanup_e2e_data(
  task_prefix             text    DEFAULT NULL,
  delete_created_groups   boolean DEFAULT false
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- KIT ADDITION (not in donor): hard-limit the RPC to tagged QA accounts.
  -- Adjust the pattern to your QA email convention (see module README).
  IF (SELECT email FROM auth.users WHERE id = auth.uid()) NOT LIKE 'qa-%' THEN
    RAISE EXCEPTION 'cleanup_e2e_data is restricted to QA accounts';
  END IF;

  -- Delete test rows matching prefix, owned by the calling user
  IF task_prefix IS NOT NULL THEN
    DELETE FROM tasks -- ADAPT: your main user-content table
    WHERE title LIKE (task_prefix || '%')
      AND created_by = auth.uid();
  END IF;

  -- Reset onboarding artifacts created by the calling user
  IF delete_created_groups THEN
    DELETE FROM groups -- ADAPT: your "workspace/team/family" table, or drop block
    WHERE created_by = auth.uid();
  END IF;
END;
$$;

-- Default PUBLIC execute on functions is a footgun: revoke, then grant narrowly.
-- (Donor later revoked even authenticated - if you do that, call the RPC with
-- service role from CI only. Kit default: authenticated + QA email guard above.)
REVOKE EXECUTE ON FUNCTION cleanup_e2e_data(text, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION cleanup_e2e_data(text, boolean) TO authenticated;
