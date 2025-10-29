# Blue/Green Nginx Auto-Failover (Stage 2 DevOps)

## Files
- `docker-compose.yml`
- `nginx/nginx.conf.template`
- `nginx/entrypoint.sh`
- `.env.example`
- `ci/test_failover.sh`
- `.github/workflows/verify.yml`

## Quick local run
1. Copy `.env.example` to `.env` and set the real image names (or use the images provided).
2. Ensure `nginx/entrypoint.sh` is executable: `chmod +x nginx/entrypoint.sh`
3. Start services:
   ```bash
   docker compose up -d
   ```  
4. verify baseline  
   ```bash  
   curl -I http://localhost:8080/version
   ```  
5. simulate failure  
   ```bash  
   curl -X POST "http://localhost:8081/chaos/start?mode=error"
   ```  
6. Run  CI tests  locally 
   ```bash  
   chmod +x ci/test_failover.sh
   ./ci/test_failover.sh
   ```  
