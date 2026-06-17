-- 1. Wipe out any test orders
DELETE FROM public.orders;

-- 2. Reset all static outlet queues to zero
UPDATE public.outlets SET queue_count = 0, wait_time = 'No wait';

-- 3. Create a Smart Function to calculate active queue and wait time
CREATE OR REPLACE FUNCTION update_outlet_queue()
RETURNS TRIGGER AS $$
DECLARE
    active_count INTEGER;
    target_outlet_id TEXT;
BEGIN
    -- Identify which outlet was affected
    target_outlet_id := COALESCE(NEW.outlet_id, OLD.outlet_id);

    -- Count active orders (pending, prep, ready) for this outlet
    SELECT COUNT(*) INTO active_count 
    FROM public.orders 
    WHERE outlet_id = target_outlet_id 
      AND status IN ('pending', 'prep', 'ready');
    
    -- Update the outlet with live numbers (Assuming 2 mins per order)
    UPDATE public.outlets 
    SET queue_count = active_count,
        wait_time = CASE 
            WHEN active_count = 0 THEN 'No wait'
            ELSE (active_count * 2)::text || '-' || (active_count * 2 + 3)::text || ' mins'
        END
    WHERE id = target_outlet_id;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 4. Attach the trigger to listen to the orders table
DROP TRIGGER IF EXISTS trigger_update_queue ON public.orders;
CREATE TRIGGER trigger_update_queue
AFTER INSERT OR UPDATE OR DELETE ON public.orders
FOR EACH ROW EXECUTE FUNCTION update_outlet_queue();
