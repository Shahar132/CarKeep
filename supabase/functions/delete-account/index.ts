import { withSupabase } from 'npm:@supabase/server@^1';
export default {
  fetch: withSupabase({
    auth: 'user'
  }, async (_req, ctx)=>{
    const userId = ctx.userClaims.id;
    try {
      // --------------------------------------------------
      // 1. Find vehicles owned by the current user.
      // --------------------------------------------------
      const { data: ownerMemberships, error: ownerMembershipsError } = await ctx.supabaseAdmin.from('vehicle_members').select('vehicle_id').eq('user_id', userId).eq('role', 'owner');
      if (ownerMembershipsError) {
        console.error('Failed loading owned vehicles:', ownerMembershipsError);
        return Response.json({
          success: false,
          code: 'DELETE_FAILED',
          message: 'לא הצלחנו לבדוק את הרכבים של החשבון.'
        }, {
          status: 500
        });
      }
      const ownedVehicleIds = ownerMemberships?.map((membership)=>membership.vehicle_id) ?? [];
      // --------------------------------------------------
      // 2. Before deleting anything, make sure that
      //    every owned vehicle has no other members.
      //
      //    If another member exists, ownership must
      //    be transferred first.
      // --------------------------------------------------
      for (const vehicleId of ownedVehicleIds){
        const { data: vehicleMembers, error: vehicleMembersError } = await ctx.supabaseAdmin.from('vehicle_members').select('user_id').eq('vehicle_id', vehicleId);
        if (vehicleMembersError) {
          console.error('Failed loading vehicle members:', vehicleMembersError);
          return Response.json({
            success: false,
            code: 'DELETE_FAILED',
            message: 'לא הצלחנו לבדוק את משתמשי הרכב.'
          }, {
            status: 500
          });
        }
        const hasOtherMembers = vehicleMembers?.some((member)=>member.user_id !== userId) ?? false;
        if (hasOtherMembers) {
          return Response.json({
            success: false,
            code: 'OWNERSHIP_TRANSFER_REQUIRED',
            message: 'יש להעביר בעלות על הרכב לפני מחיקת החשבון.'
          }, {
            status: 409
          });
        }
      }
      // --------------------------------------------------
      // 3. Save the Storage file paths BEFORE deleting
      //    the account.
      //
      //    The database trigger will delete solo-owned
      //    vehicles and their document rows, so after the
      //    user is deleted we would no longer be able to
      //    read these paths from the documents table.
      // --------------------------------------------------
      let documentFilePaths = [];
      if (ownedVehicleIds.length > 0) {
        const { data: documentRows, error: documentsError } = await ctx.supabaseAdmin.from('documents').select('file_path').in('vehicle_id', ownedVehicleIds);
        if (documentsError) {
          console.error('Failed loading document paths:', documentsError);
          return Response.json({
            success: false,
            code: 'DELETE_FAILED',
            message: 'לא הצלחנו לבדוק את מסמכי הרכב.'
          }, {
            status: 500
          });
        }
        documentFilePaths = documentRows?.map((document)=>document.file_path).filter((path)=>typeof path === 'string' && path.trim().length > 0) ?? [];
      }
      // --------------------------------------------------
      // 4. Delete the Auth user.
      //
      //    Our database BEFORE DELETE trigger handles:
      //
      //    - member/admin memberships
      //    - solo-owned vehicles
      //    - database cascade cleanup
      // --------------------------------------------------
      const { error: deleteUserError } = await ctx.supabaseAdmin.auth.admin.deleteUser(userId);
      if (deleteUserError) {
        console.error('Delete account error:', deleteUserError);
        if (deleteUserError.message.includes('OWNERSHIP_TRANSFER_REQUIRED')) {
          return Response.json({
            success: false,
            code: 'OWNERSHIP_TRANSFER_REQUIRED',
            message: 'יש להעביר בעלות על הרכב לפני מחיקת החשבון.'
          }, {
            status: 409
          });
        }
        return Response.json({
          success: false,
          code: 'DELETE_FAILED',
          message: 'לא הצלחנו למחוק את החשבון.'
        }, {
          status: 500
        });
      }
      // --------------------------------------------------
      // 5. The account and database data are now gone.
      //    Remove the physical files from Storage.
      //
      //    We do this AFTER successful account deletion so
      //    a failed account deletion can never leave DB
      //    document rows pointing to missing files.
      // --------------------------------------------------
      if (documentFilePaths.length > 0) {
        const chunkSize = 100;
        for(let i = 0; i < documentFilePaths.length; i += chunkSize){
          const pathsChunk = documentFilePaths.slice(i, i + chunkSize);
          const { error: storageError } = await ctx.supabaseAdmin.storage.from('vehicle-documents').remove(pathsChunk);
          if (storageError) {
            // The account is already deleted,
            // therefore we only log this failure.
            // We must not tell the client that the
            // account deletion itself failed.
            console.error('Storage cleanup failed:', storageError);
          }
        }
      }
      return Response.json({
        success: true
      });
    } catch (error) {
      console.error('Unexpected delete account error:', error);
      const message = error instanceof Error ? error.message : '';
      if (message.includes('OWNERSHIP_TRANSFER_REQUIRED')) {
        return Response.json({
          success: false,
          code: 'OWNERSHIP_TRANSFER_REQUIRED',
          message: 'יש להעביר בעלות על הרכב לפני מחיקת החשבון.'
        }, {
          status: 409
        });
      }
      return Response.json({
        success: false,
        code: 'DELETE_FAILED',
        message: 'לא הצלחנו למחוק את החשבון.'
      }, {
        status: 500
      });
    }
  })
};
