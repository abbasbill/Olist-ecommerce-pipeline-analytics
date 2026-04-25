#  START HERE - Immediate Deployment Instructions

** Time to Production: 10 minutes**  
** Goal: Get dbt pipeline running in Kestra**  
** Status: All files pre-configured, ready to execute**

---

## CRITICAL: One-Time Docker Setup

**Do this FIRST before running Kestra:**

### 1. Update docker-compose.yml

Open `docker-compose.yml` and find the `kestra:` service's `volumes:` section.

**ADD THIS LINE:**
```yaml
- /home/sxzquare/Olist-ecommerce-pipeline-analytics/olist_analytics:/app/olist_analytics
```

**Full volumes section should look like:**
```yaml
kestra:
  # ... other config ...
  volumes:
    - kestra-data:/app/storage
    - /var/run/docker.sock:/var/run/docker.sock
    - /tmp/kestra-wd:/tmp/kestra-wd
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/flows:/app/flows
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/terraform:/app/terraform
    - /home/sxzquare/Olist-ecommerce-pipeline-analytics/olist_analytics:/app/olist_analytics  # ← ADD THIS
```

### 2. Restart Kestra

```bash
docker compose down
docker compose up -d
```

**Wait 30-60 seconds for services to fully start.**

### 3. Verify Services Are Running

```bash
docker compose ps
```

Should show:
```
NAME      STATUS                  PORTS
postgres  Up (healthy)            5432/tcp
kestra    Up                      18080->8080/tcp
```

---

## ✅ One-Time Setup Complete

You only need to do the above once. Now proceed to deployment.

---

## 🚀 DEPLOY THE PIPELINE (5 Minutes)

### Step 1: Open Kestra UI

Go to: http://localhost:18080

### Step 2: Find Your Flow

Click **Flows** in the left sidebar.

Look for: `olist_sales_dbt_pipeline`

> **If you don't see it**, skip to "Upload Flow Manually" section below.

### Step 3: Execute the Pipeline

1. Click the flow name
2. Click the **Execute Now** button (green play button)
3. Watch the task execution:

```
Executing...
├─ dbt_deps                    [⏳ Running...] → [✓ Complete] ~30 sec
├─ run_dbt_transformations     [⏳ Running...] → [✓ Complete] 2-5 min
├─ run_dbt_tests               [⏳ Running...] → [✓ Complete] 1-2 min
├─ generate_dbt_docs           [⏳ Running...] → [✓ Complete] ~30 sec
└─ success_notification        [✓ Complete]    Instant

 COMPLETE! Total: ~5-10 minutes
```

### Step 4: Verify Success

Check the execution log for:
-  "All tasks completed successfully"
-  "19 tests passed, 0 failures"
-  No red error messages

---

## Flow Not Showing? Upload Manually

If you don't see `olist_sales_dbt_pipeline` in Kestra:

1. In Kestra UI, click **Flows** → **+ Create** → **New flow**
2. Open file: `flows/olist_dbt_transformations.yml`
3. Copy the entire contents
4. Paste into Kestra editor
5. Click **Save**
6. Now you can execute it

---

## Verify in BigQuery

After execution completes, verify in BigQuery console:

```sql
-- Check the data was created
SELECT COUNT(*) as row_count 
FROM `ecommerce-4939.olist_dataset_4939.fct_sales`;

-- Expected output: ~112,000 rows
```

---

## 📈 Next Step: Create Dashboard (Optional)

Once pipeline succeeds:

1. Open Looker Studio: https://datastudio.google.com
2. Create → Report
3. Connect BigQuery → Select `ecommerce-4939` → `olist_dataset_4939` → `fct_sales`
4. Add two charts:
   - **Revenue by Category** (Horizontal bar)
   - **Monthly Revenue Trend** (Line chart)

See [LOOKER_STUDIO_GUIDE.md](./LOOKER_STUDIO_GUIDE.md) for details.

---

## Common Issues & Fixes

| Problem | Solution |
|---------|----------|
| Flow not showing in Kestra | Upload manually (see section above) |
| "Volume not mounted" error | Add line to docker-compose.yml, restart |
| Tasks failing with "Connection refused" | Verify GCP secrets in Kestra Admin |
| "Table not found" error | Verify raw tables exist in `olist_dataset_4939` |

---

## Quick Checklist Before Clicking Execute

- [ ] Docker: `docker compose ps` shows both services up
- [ ] Kestra accessible: http://localhost:18080 loads
- [ ] docker-compose.yml has `/app/olist_analytics` volume mounted
- [ ] Flow visible in Kestra (or manually uploaded)
- [ ] GCP dataset `olist_dataset_4939` exists in BigQuery

If all ✓, you're ready!

---

## Success Indicators

✅ Pipeline successful when:

1. All 5 tasks show green checkmarks in Kestra
2. Logs show "19 tests passed, 0 failures"
3. BigQuery query returns ~112,000 rows from fct_sales
4. No red error messages in task logs

---

## Schedule Daily Runs

**Already configured!** Flow runs daily at 2 AM UTC.

To modify:
1. Go to Kestra → Flow → **Edit**
2. Find `triggers:` section
3. Change cron: `0 2 * * *` (2 AM UTC)
4. Save

---

## Help

**Need help?** Check these files:
- [DEPLOYMENT_READY.md](./DEPLOYMENT_READY.md) - Full deployment guide
- [VERIFY_BEFORE_RUN.md](./VERIFY_BEFORE_RUN.md) - Pre-flight checklist
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System overview

---

## Ready?

**That's it! You're ready to deploy.**

1. Update docker-compose.yml (add volume)
2. Restart Kestra: `docker compose down && docker compose up -d`
3. Open Kestra: http://localhost:18080
4. Find flow: `olist_sales_dbt_pipeline`
5. Click **Execute Now**
6. Wait 5-10 minutes
7. Done! ✅

---

**Deployment Configuration:**
- Project: ecommerce-4939
- Dataset: olist_dataset_4939
- Email: sxzquare@gmail.com #replace with your email
- Status: ✅ READY
