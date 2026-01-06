from datetime import datetime, timedelta
from flask import jsonify
 
@app.route('/api/companies/<int:company_id>/alerts/low-stock', methods=['GET'])
def low_stock_alerts(company_id):
    """
    Returns low-stock alerts for a company across all warehouses.
    """

    alerts = []

    # configurable business rule
    RECENT_SALES_DAYS = 30
    since_date = datetime.utcnow() - timedelta(days=RECENT_SALES_DAYS)

    # Example threshold mapping by product type
    THRESHOLD_BY_TYPE = {
        "fast_moving": 20,
        "regular": 10,
        "slow_moving": 5
    }

    # Fetch all inventory for the company
    inventories = db.session.execute("""
        SELECT
            p.id AS product_id,
            p.name AS product_name,
            p.sku,
            p.product_type,
            w.id AS warehouse_id,
            w.name AS warehouse_name,
            i.quantity
        FROM inventory i
        JOIN product p ON p.id = i.product_id
        JOIN warehouse w ON w.id = i.warehouse_id
        WHERE p.company_id = :company_id
    """, {"company_id": company_id}).fetchall()

    for row in inventories:
        threshold = THRESHOLD_BY_TYPE.get(row.product_type, 10)

        # Skip if stock is not low
        if row.quantity >= threshold:
            continue

        # Check recent sales activity
        recent_sales = db.session.execute("""
            SELECT 1
            FROM inventory_transaction
            WHERE product_id = :product_id
              AND warehouse_id = :warehouse_id
              AND change_quantity < 0
              AND created_at >= :since_date
            LIMIT 1
        """, {
            "product_id": row.product_id,
            "warehouse_id": row.warehouse_id,
            "since_date": since_date
        }).fetchone()

        if not recent_sales:
            continue

        # Fetch supplier info
        supplier = db.session.execute("""
            SELECT s.id, s.name, s.contact_email
            FROM supplier s
            JOIN supplier_product sp ON sp.supplier_id = s.id
            WHERE sp.product_id = :product_id
            LIMIT 1
        """, {"product_id": row.product_id}).fetchone()

        alerts.append({
            "product_id": row.product_id,
            "product_name": row.product_name,
            "sku": row.sku,
            "warehouse_id": row.warehouse_id,
            "warehouse_name": row.warehouse_name,
            "current_stock": row.quantity,
            "threshold": threshold,
            "days_until_stockout": None,  # calculated below
            "supplier": {
                "id": supplier.id if supplier else None,
                "name": supplier.name if supplier else None,
                "contact_email": supplier.contact_email if supplier else None
            }
        })

    return jsonify({
        "alerts": alerts,
        "total_alerts": len(alerts)
    }), 200
