
CREATE TYPE public.expense_split_type AS ENUM ('equal', 'custom');
CREATE TYPE public.expense_share_status AS ENUM ('pending', 'paid');

CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  description TEXT NOT NULL CHECK (length(trim(description)) > 0 AND length(description) <= 120),
  total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount > 0),
  split_type public.expense_split_type NOT NULL DEFAULT 'equal',
  upi_id TEXT CHECK (upi_id IS NULL OR upi_id ~ '^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.expenses TO authenticated;
GRANT ALL ON public.expenses TO service_role;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view expenses"
  ON public.expenses FOR SELECT TO authenticated
  USING (public.has_activity_access(activity_id, auth.uid()));

CREATE POLICY "Members can create expenses"
  ON public.expenses FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by AND public.has_activity_access(activity_id, auth.uid()));

CREATE POLICY "Creators can update expenses"
  ON public.expenses FOR UPDATE TO authenticated
  USING (auth.uid() = created_by) WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Creators can delete expenses"
  ON public.expenses FOR DELETE TO authenticated
  USING (auth.uid() = created_by);

CREATE TRIGGER trg_expenses_updated_at
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

CREATE INDEX idx_expenses_activity ON public.expenses(activity_id, created_at DESC);

CREATE TABLE public.expense_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  status public.expense_share_status NOT NULL DEFAULT 'pending',
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (expense_id, user_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.expense_shares TO authenticated;
GRANT ALL ON public.expense_shares TO service_role;
ALTER TABLE public.expense_shares ENABLE ROW LEVEL SECURITY;

-- Members of the plan can view shares
CREATE POLICY "Members can view expense shares"
  ON public.expense_shares FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id AND public.has_activity_access(e.activity_id, auth.uid())
  ));

-- Only the expense creator inserts shares (during creation flow)
CREATE POLICY "Creators can insert expense shares"
  ON public.expense_shares FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id AND e.created_by = auth.uid()
  ));

-- Expense creator OR the share owner can update status (mark paid)
CREATE POLICY "Creator or share owner can update share"
  ON public.expense_shares FOR UPDATE TO authenticated
  USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_id AND e.created_by = auth.uid())
  )
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_id AND e.created_by = auth.uid())
  );

CREATE POLICY "Creator can delete shares"
  ON public.expense_shares FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = expense_id AND e.created_by = auth.uid()));

CREATE TRIGGER trg_expense_shares_updated_at
  BEFORE UPDATE ON public.expense_shares
  FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

CREATE INDEX idx_expense_shares_expense ON public.expense_shares(expense_id);
CREATE INDEX idx_expense_shares_user_pending ON public.expense_shares(user_id) WHERE status = 'pending';

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.expense_shares;
