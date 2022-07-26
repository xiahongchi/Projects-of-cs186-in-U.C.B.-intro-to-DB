package edu.berkeley.cs186.database.concurrency;

import edu.berkeley.cs186.database.TransactionContext;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * LockUtil is a declarative layer which simplifies multigranularity lock
 * acquisition for the user (you, in the last task of Part 2). Generally
 * speaking, you should use LockUtil for lock acquisition instead of calling
 * LockContext methods directly.
 */
public class LockUtil {
    /**
     * Ensure that the current transaction can perform actions requiring
     * `requestType` on `lockContext`.
     * <p>
     * `requestType` is guaranteed to be one of: S, X, NL.
     * <p>
     * This method should promote/escalate/acquire as needed, but should only
     * grant the least permissive set of locks needed. We recommend that you
     * think about what to do in each of the following cases:
     * - The current lock type can effectively substitute the requested type
     * - The current lock type is IX and the requested lock is S
     * - The current lock type is an intent lock
     * - None of the above: In this case, consider what values the explicit
     * lock type can be, and think about how ancestor looks will need to be
     * acquired or changed.
     * <p>
     * You may find it useful to create a helper method that ensures you have
     * the appropriate locks on all ancestors.
     */
    public static void ensureSufficientLockHeld(LockContext lockContext, LockType requestType) {
        // requestType must be S, X, or NL
        assert (requestType == LockType.S || requestType == LockType.X || requestType == LockType.NL);

        // Do nothing if the transaction or lockContext is null
        TransactionContext transaction = TransactionContext.getTransaction();
        if (transaction == null || lockContext == null) return;

        // You may find these variables useful
        LockContext parentContext = lockContext.parentContext();
        LockType effectiveLockType = lockContext.getEffectiveLockType(transaction);
        LockType explicitLockType = lockContext.getExplicitLockType(transaction);

        // TODO(proj4_part2): implement
        if ((requestType == LockType.S && (effectiveLockType == LockType.S || effectiveLockType == LockType.X))
                || (requestType == LockType.X && effectiveLockType == LockType.X)
                || requestType == LockType.NL)
            return;


        if (requestType == LockType.S) {// possible current and ancestors' type: IS, IX, NL
            switch (explicitLockType) {
                case IS:
                    // escalating is enough
                    lockContext.escalate(transaction);
                    break;
                case IX:
                    // promote to SIX
                    lockContext.promote(transaction, LockType.SIX);
                    break;
                case NL:
                    // ensure appropriate locks on all ancestors
                    LockContext lockContext1 = parentContext;
                    List<LockContext> AncestorsContexts = new ArrayList<>();
                    while (lockContext1 != null) {

                        if (lockContext1.getExplicitLockType(transaction) == LockType.IS
                                || lockContext1.getExplicitLockType(transaction) == LockType.IX) {
                            break;
                        }


                        // add to list
                        AncestorsContexts.add(lockContext1);
                        // update
                        lockContext1 = lockContext1.parentContext();
                    }

                    Collections.reverse(AncestorsContexts);
                    // IS down
                    for (LockContext lockContext2 : AncestorsContexts) {
                        lockContext2.acquire(transaction, LockType.IS);
                    }
                    // add Lock S
                    lockContext.acquire(transaction, LockType.S);

                    break;
            }
            return;
        } else {// requestType = X
            // possible current type: IS, IX, NL, S, SIX
            switch (explicitLockType) {
                case IX:
                case SIX:
                    // escalate first
                    lockContext.escalate(transaction);
                    // promote to X
                    lockContext.promote(transaction, LockType.X);
                    break;
                case S:
                case IS:
                case NL:
                    // ensure appropriate locks on all ancestors
                    LockContext lockContext1 = parentContext;
                    List<LockContext> AncestorsContexts = new ArrayList<>();
                    while (lockContext1 != null) {

                        if (lockContext1.getExplicitLockType(transaction) == LockType.IX
                                || lockContext1.getExplicitLockType(transaction) == LockType.SIX) {
                            break;
                        }

                        // add to list
                        AncestorsContexts.add(lockContext1);
                        // update
                        lockContext1 = lockContext1.parentContext();
                    }
                    Collections.reverse(AncestorsContexts);
                    // IX down
                    for (LockContext lockContext2 : AncestorsContexts) {
                        if (lockContext2.getExplicitLockType(transaction) == LockType.S)
                            lockContext2.promote(transaction, LockType.SIX);
                        else if(lockContext2.getExplicitLockType(transaction) == LockType.IS)
                            lockContext2.promote(transaction, LockType.IX);
                        else
                            lockContext2.acquire(transaction, LockType.IX);
                    }
                    // escalate if necessary
                    if(lockContext.getExplicitLockType(transaction) == LockType.NL){
                        lockContext.acquire(transaction, LockType.X);
                    }
                    else{
                        lockContext.escalate(transaction);
                        // acquire and release from S to Lock X if needed
                        if(lockContext.getExplicitLockType(transaction) == LockType.S){
                            lockContext.promote(transaction, LockType.X);
                        }
                    }
                    break;
            }
        }

        return;

        // TODO(proj4_part2) add any helper methods you want
    }
}
