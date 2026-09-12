from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.database.models import User, Transfer, TransferItem, Inventory, ActivityLog, Notification
from app.security import get_current_user
from app.schemas.schemas import TransferCreate

router = APIRouter(prefix="/transfers", tags=["Transfers"])


@router.get("")
def list_transfers(status: Optional[str] = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    q = db.query(Transfer)
    if status:
        q = q.filter(Transfer.status == status)
    transfers = q.order_by(Transfer.created_at.desc()).limit(100).all()
    out = []
    for t in transfers:
        out.append({
            "id": t.id, "from_branch": t.from_branch.name, "to_branch": t.to_branch.name,
            "status": t.status, "created_at": t.created_at, "completed_at": t.completed_at,
            "items": [{"product": i.product.name, "quantity": i.quantity} for i in t.items],
        })
    return out


@router.post("")
def create_transfer(payload: TransferCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    if payload.from_branch_id == payload.to_branch_id:
        raise HTTPException(status_code=400, detail="Source and destination branches must differ")
    transfer = Transfer(
        from_branch_id=payload.from_branch_id, to_branch_id=payload.to_branch_id,
        status="Pending", requested_by=user.id, created_at=datetime.utcnow(),
    )
    db.add(transfer)
    db.flush()
    for item in payload.items:
        db.add(TransferItem(transfer_id=transfer.id, product_id=item.product_id, quantity=item.quantity))

    db.add(ActivityLog(
        company_id=user.company_id, user_id=user.id, branch_id=payload.from_branch_id,
        action="requested a stock transfer", entity_type="transfer", entity_id=transfer.id,
        description=f"{user.name} requested a stock transfer (#{transfer.id})",
    ))
    db.add(Notification(
        company_id=user.company_id, branch_id=payload.to_branch_id, type="transfer_required",
        title=f"Transfer awaiting approval — #{transfer.id}",
        message=f"A new stock transfer request (#{transfer.id}) needs approval.",
        severity="warning", related_entity_type="transfer", related_entity_id=transfer.id,
        recommended_action="Review and approve or reject the transfer.",
    ))
    db.commit()
    return {"id": transfer.id, "status": transfer.status}


@router.patch("/{transfer_id}/approve")
def approve_transfer(transfer_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    transfer = db.query(Transfer).filter(Transfer.id == transfer_id).first()
    if not transfer:
        raise HTTPException(status_code=404, detail="Transfer not found")
    if transfer.status != "Pending":
        raise HTTPException(status_code=400, detail=f"Transfer is already {transfer.status}")

    # Simulate stock movement
    for item in transfer.items:
        from_inv = db.query(Inventory).filter(
            Inventory.branch_id == transfer.from_branch_id, Inventory.product_id == item.product_id
        ).first()
        to_inv = db.query(Inventory).filter(
            Inventory.branch_id == transfer.to_branch_id, Inventory.product_id == item.product_id
        ).first()
        if from_inv:
            from_inv.quantity = max(0, from_inv.quantity - item.quantity)
            from_inv.last_updated = datetime.utcnow()
        if to_inv:
            to_inv.quantity += item.quantity
            to_inv.last_updated = datetime.utcnow()
        else:
            db.add(Inventory(branch_id=transfer.to_branch_id, product_id=item.product_id,
                              quantity=item.quantity, last_updated=datetime.utcnow()))

    transfer.status = "Completed"
    transfer.approved_by = user.id
    transfer.completed_at = datetime.utcnow()

    db.add(ActivityLog(
        company_id=user.company_id, user_id=user.id, branch_id=transfer.to_branch_id,
        action="approved a stock transfer", entity_type="transfer", entity_id=transfer.id,
        description=f"{user.name} approved transfer #{transfer.id}",
    ))
    db.add(Notification(
        company_id=user.company_id, branch_id=transfer.to_branch_id, type="transfer_completed",
        title=f"Transfer #{transfer.id} completed",
        message=f"Stock transfer #{transfer.id} was approved and inventory was updated.",
        severity="info", related_entity_type="transfer", related_entity_id=transfer.id,
    ))
    db.commit()
    return {"id": transfer.id, "status": transfer.status}


@router.patch("/{transfer_id}/reject")
def reject_transfer(transfer_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    transfer = db.query(Transfer).filter(Transfer.id == transfer_id).first()
    if not transfer:
        raise HTTPException(status_code=404, detail="Transfer not found")
    if transfer.status != "Pending":
        raise HTTPException(status_code=400, detail=f"Transfer is already {transfer.status}")

    transfer.status = "Rejected"
    transfer.approved_by = user.id
    transfer.completed_at = datetime.utcnow()
    db.add(ActivityLog(
        company_id=user.company_id, user_id=user.id, branch_id=transfer.to_branch_id,
        action="rejected a stock transfer", entity_type="transfer", entity_id=transfer.id,
        description=f"{user.name} rejected transfer #{transfer.id}",
    ))
    db.commit()
    return {"id": transfer.id, "status": transfer.status}
