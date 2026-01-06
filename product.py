from decimal import Decimal, InvalidOperation 
from sqlalchemy.exc import IntegrityError

@app.route('/api/products', methods=['POST'])
def create_product():
    # fetching data
    data = request.get_json(silent=True)
    if not data:
        return {"error": "Invalid JSON body"}, 400                  # if request.json is none 
    # validate i/p data
    required = ["name", "sku", "price"]
    for field in required:
        if field not in data:
            return {"error": f"{field} is required"}, 400               # prevents missing or invalid data
    warehouse_id = data.get("warehouse_id")                   # products can be in multiple warehouses
    initial_quantity = data.get("initial_quantity", 0)              # takes initial quantity else default 0
    # check price value
    try:
        price = Decimal(str(data["price"]))
        if price < 0:                                                                     # price can’t be negative
            raise ValueError
    except (InvalidOperation, ValueError):
        return {"error": "Invalid price value"}, 400

    # check quantity value
    if initial_quantity < 0:
        return {"error": "Quantity cannot be negative"}, 400
    
    # create product
    try:                                                                         
        product = Product(
            name=data["name"],
            sku=data["sku"],
            price=price,
        )

        db.session.add(product)                 # add() stages the object for insertion
        db.session.flush()                                 # flush() sends it to the database to generate the primary key
        db.session.commit()                       # permanently saves all pending database changes
        return {
            "message": "Product created successfully",
            "product_id": product.id
        }, 201                                              # returns json response after successful creation

    except IntegrityError:
        db.session.rollback()
        return {
            "error": "SKU must be unique or warehouse does not exist"      # unique sku required
        }, 409

    except Exception:
        db.session.rollback()
        return {"error": "Internal server error"}, 500


