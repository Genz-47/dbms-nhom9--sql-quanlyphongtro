




-----------------------------Store Procedure-----------------------------

---------------lay so luong phòng còn trống------------
go
Create proc SLptrong
as 
begin
   select count(MAPHONG) as soluongcontrong
   from PHONGTRO
   where HIENTRANGPHONG='false'
   group by MAPHONG
end

--execute sp_Thongkhthang9;

--go

----liet ke những hóa đơn được lập sau khi thanh toán 1 trở lên
go
Create proc sp_ktHoaDon
as
select MAHD,HOADON.MAPTT,NGAYLAPHD,THUEVAT
from HOADON,PHIEUTHANHTOAN
where PHIEUTHANHTOAN.MAPTT=HOADON.MAPTT and (HOADON.NGAYLAPHD-PHIEUTHANHTOAN.NGAYTT)>=1

----------thống kê những khác hàng không sử dụng DV------------
go
Create proc khongDV
as 
begin
   select KHACHHANG.MAKH,TENKH,KHACHHANG.NGAYSINH,NGHENGHIEP,MAPDK
   from KHACHHANG,PHIEUDANGKY
   where KHACHHANG.MAKH=PHIEUDANGKY.MAKH and PHIEUDANGKY.MAPDK not in (select MAPDK from DANGKY_DV)
end

----liet ke cac dich vu được nhiều khách hàng sử dụng nhất
go
Create proc sp_ktdichvu
as
begin
select *
from DICHVU left outer join (select DANGKY_DV.MADV,COUNT(MAPDK) as sl
    from DANGKY_DV
    group by MADV) as sldk on DICHVU.MADV=sldk.MADV
where sldk.sl>=all((select COUNT(MAPDK) as sl
    from DANGKY_DV
    group by MADV))
end

-------KHACHHANG-------
CREATE PROCEDURE  sp_CapnhatKhachHang
    @MaKH nchar(10),
	@TenKH nvarchar(10),
	@NgaySinh date,
	@Socmnd nvarchar(10),
	@DiaChi nvarchar(10),
	@NgheNghiep nvarchar(10),
	@SDT nvarchar(10)
AS
Begin
begin tran
	if(@TenKH='')
		begin
			raiserror('Họ tên khách hàng không được để trống!', 16, 1)
			rollback
			return
		end
   Update KHACHHANG
   set MAKH=@MaKH,TENKH=@TenKH,NGAYSINH=@NgaySinh,SOCMND=@Socmnd,DIACHI=@DiaChi,NGHENGHIEP=@NgheNghiep,SDT=@SDT
   where MAKH=@MaKH
End
if(@@ERROR <> 0)
	begin
		raiserror('Error', 16,1)
		rollback
		return
	end
commit tran

-- Thêm khách hàng
create proc sp_themKhachHang
@MaKH nchar(10),
@TenKH nvarchar(20),
@NgaySinh date,
@CMND int,
@DiaChi nvarchar(50),
@NgheNghiep nvarchar(50),
@SDT int
as
begin 

	if(@MaKH is null)
	begin
		raiserror('Ma khach hang khong duoc bo trong!', 16, 1)
		rollback
		return
	end

	if(@TenKH = '')
	begin
		raiserror('Ho Ten khach hang khong duoc bo trong!', 16, 1)
		rollback
		return
	end

	if(@NgaySinh > getdate())
	begin
		raiserror('Ngày sinh khach hang khong duoc lon hon ngay hien tai!', 16, 1)
		rollback
		return
	end

	if(@CMND = '')
	begin
		raiserror('CMND khach hang khong duoc bo trong!', 16, 1)
		rollback
		return
	end

	insert into KHACHHANG values(@MaKH,@TenKH,@NgaySinh,@CMND,@DiaChi,@NgheNghiep,@SDT)
	exec dbo.sp_addTaiKhoan @MaKH,'123'
	exec dbo.sp_addAccount @MaKH,'123'
	if(@@ERROR<>0)
	begin
		raiserror('Error',16,1)
		rollback
		return
	end
end
-- Xóa khách hàng
create proc sp_xoaKhachHang
@MaKH nchar(10)
as

begin 

	exec sp_deleteTaiKhoan @MaKH
	exec sp_deleteAccount @MaKH
	delete from KHACHHANG
	where MAKH = @MaKH
	if (@@ERROR<>0)
	begin
		raiserror ('Error',16,1)
		rollback tran
		return
	end
end


-------PHIEUDANGKY-------

--Thêm phiếu đăng ký

CREATE PROCEDURE sp_themPDK
    @MaPDK nchar(10),
	@MaKH nchar(10),
	@NGAYTHUE date,
	@NGAYTRA date,
	@SOPHONG nvarchar(10),
	@MaTB nchar(10),
	@TRATRUOC float,
	@TRASAU float,
	@CHUTHICH nvarchar(10)
as
declare @kqMaKH nchar(10)
begin tran
if(@MaKH is null)
begin
raiserror('Mã khách hàng không được để trống', 16, 1)
rollback
return
end
if(@MaPDK ='')
begin
raiserror('Phiếu Đăng Ký không được để trống', 16, 1)
rollback
return
end
if(@SOPHONG ='')
begin
raiserror('Phải nhập số phòng khách hàng', 16, 1)
rollback
return
end
if(@MaPDK in (select MAPDK from PHIEUDANGKY))
begin
raiserror ('Mã Phiếu Đăng Ký đã bị trùng! Vui lòng nhập lại.',16,1)
rollback
return
end
insert into PHIEUDANGKY values (@MaPDK,@MaKH,@NGAYTHUE,@NGAYTRA,@SOPHONG,@MaTB,@TRATRUOC,@TRASAU,@CHUTHICH)
if(@@ERROR <>0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran


-- Chỉnh sửa phiếu đăng ký--
CREATE PROCEDURE  sp_CapNhatPDK
   @MaPDK nchar(10),
	@MaKH nchar(10),
	@NGAYTHUE date,
	@NGAYTRA date,
	@SOPHONG nvarchar(10),
	@MaTB nchar(10),
	@TRATRUOC float,
	@TRASAU float,
	@CHUTHICH nvarchar(10)
AS
Begin
begin tran
if(@NGAYTHUE='')
begin
raiserror('ngay thue không được để trống!', 16, 1)
rollback
return
end
   Update PHIEUDANGKY
   set MAKH=@MaKH, MAPDK=@MaPDK,NGAYTHUE=@NGAYTHUE,NGAYTRA=@NGAYTRA,SOPHONG=@SOPHONG,MATB=@MaTB,TRATRUOC=@TRATRUOC,TRASAU=@TRASAU,CHUTHICH=@CHUTHICH
   where MAPDK=@MaPDK
End
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran


--Xóa phiếu đăng ký--
CREATE PROCEDURE sp_xoaPDK
@MaPDK nchar(10)
as
begin tran
		delete from PHIEUDANGKY
		where MAPDK = @MaPDK
	if(@@ERROR <> 0)
	begin
		raiserror('Error', 16,1)
		rollback
		return
	end
commit tran


-------PHIEUTHANHTOAN-------
--Thêm phiếu thanh toán
CREATE PROCEDURE sp_themPTT
    @MaPTT nchar(10),
	@MaPDK nchar(10),	
	@SOTHANG int,
	@NGAYTT date,
	@TONGTIEN float
as
declare @kqMaKH nchar(10)
begin tran
if(@MaPTT is null)
begin
raiserror('Mã Phiếu Thanh Toán không được để trống', 16, 1)
rollback
return
end
if(@MaPDK ='')
begin
raiserror('Phiếu Đăng Ký không được để trống', 16, 1)
rollback
return
end
if(@SOTHANG ='')
begin
raiserror('Phải nhập số tháng khách hàng', 16, 1)
rollback
return
end
if(@MaPTT in (select MAPTT from PHIEUTHANHTOAN))
begin
raiserror ('Mã Phiếu THanh Toán đã bị trùng! Vui lòng nhập lại.',16,1)
rollback
return
end
insert into PHIEUTHANHTOAN values (@MaPTT,@MaPDK,@SOTHANG,@NGAYTT,@TONGTIEN)
if(@@ERROR <>0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-- Sửa phiếu thanh toán
CREATE PROCEDURE  sp_CapNhatPTT
    @MaPTT nchar(10),
	@MaPDK nchar(10),	
	@SOTHANG int,
	@NGAYTT date,
	@TONGTIEN float
AS
Begin
begin tran
if(@SOTHANG='')
begin
raiserror('tháng thuê không được để trống!', 16, 1)
rollback
return
end
   Update PHIEUTHANHTOAN
   set MAPTT=@MaPTT, MAPDK=@MaPDK,SOTHANG=@SOTHANG,NGAYTT=@NGAYTT,TONGTIEN=@TONGTIEN
   where MAPTT=@MaPTT
End
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-- Xóa phiếu thanh toán.
CREATE PROCEDURE sp_xoaPTT
@MaPTT nchar(10)
as
begin tran
delete from PHIEUTHANHTOAN
where MAPTT = @MaPTT
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran


-------HOADON-------


-- Thêm hóa đơn.
CREATE PROCEDURE sp_themHoaDon
    @MAHD nchar(10),
	@MaPTT nchar(10),		
	@NGAYLAPHD date,
	@THUEVAT float
as
declare @kqMaKH nchar(10)
begin tran
if(@MaPTT is null)
begin
raiserror('Mã Phiếu Thanh Toán không được để trống', 16, 1)
rollback
return
end
if(@MAHD ='')
begin
raiserror('Mã Hóa Đơn không được để trống', 16, 1)
rollback
return
end
if(@NGAYLAPHD ='')
begin
raiserror('Phải nhập ngày lập hđ khách hàng', 16, 1)
rollback
return
end
if(@MAHD in (select MAHD from HOADON))
begin
raiserror ('Mã Hóa ĐƠn đã bị trùng! Vui lòng nhập lại.',16,1)
rollback
return
end
insert into HOADON values ( @MAHD,@MaPTT,@NGAYLAPHD,@THUEVAT)
if(@@ERROR <>0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-- Sửa hóa đơn
CREATE PROCEDURE  sp_CapNhatHoaDon
    @MAHD nchar(10),
	@MaPTT nchar(10),		
	@NGAYLAPHD date,
	@THUEVAT float
AS
Begin
begin tran
if(@NGAYLAPHD='')
begin
raiserror('ngày lập hđ không được để trống!', 16, 1)
rollback
return
end
   Update HOADON
   set  MAHD=@MAHD,MAPTT=@MaPTT,NGAYLAPHD=@NGAYLAPHD,THUEVAT=@THUEVAT
   where MAHD=@MAHD
End
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-- Xóa hóa đơn
CREATE PROCEDURE sp_xoaHoaDon
@MaHD nchar(10)
as
begin tran
	delete from HOADON
	where MAHD= @MaHD
	if(@@ERROR <> 0)
	begin
		raiserror('Error', 16,1)
		rollback
		return
	end
commit tran


-------THIETBI-------

-- Thêm thiết bị
CREATE PROCEDURE sp_themThietBi
    @MATB nchar(10),
	@TENTB nvarchar(10),		
	@GIATB float
as
begin tran
if(@MATB is null)
begin
raiserror('Mã Thiết bị không được để trống', 16, 1)
rollback
return
end
if(@TENTB ='')
begin
raiserror('Tên thiết bị không được để trống', 16, 1)
rollback
return
end
if(@GIATB ='')
begin
raiserror('Phải nhập giá TB', 16, 1)
rollback
return
end
if(@MATB in (select MATB from THIETBI))
begin
raiserror ('Mã thiết bị đã bị trùng! Vui lòng nhập lại.',16,1)
rollback
return
end
insert into THIETBI values ( @MATB,@TENTB,@GIATB)
if(@@ERROR <>0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran


--Cập nhật thiết bị 

CREATE PROCEDURE  sp_CapNhatThietBi
    @MATB nchar(10),
	@TENTB nvarchar(10),		
	@GIATB float
AS
Begin
begin tran
if(@GIATB='')
begin
raiserror('giá tb không được để trống!', 16, 1)
rollback
return
end
   Update THIETBI
   set  MATB=@MATB,TENTB=@TENTB,GIATB=@GIATB
   where MATB=@MATB
End
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran


-- Xóa thiết bị

CREATE PROCEDURE sp_xoaThietBi
@MaTB nchar(10)
as
begin tran
delete from THIETBI
where MATB= @MaTB
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-------TRANGBI-------

-- Thêm trang bị
CREATE PROCEDURE sp_themTrangBi
    @MAPHONG nchar(10),
	@MATB nchar(10),		
	@NGAYTRANGBI date
as
begin tran
if(@MAPHONG is null)
begin
raiserror('Mã phòng không được để trống', 16, 1)
rollback
return
end
if(@MATB ='')
begin
raiserror('mã thiết bị không được để trống', 16, 1)
rollback
return
end
if(@NGAYTRANGBI ='')
begin
raiserror('Phải nhập ngày trang bị', 16, 1)
rollback
return
end
insert into TRANGBI values ( @MAPHONG,@MATB,@NGAYTRANGBI)
if(@@ERROR <>0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-- Cập nhật trang bị

CREATE PROCEDURE  sp_CapNhatTrangBi
    @MAPHONG nchar(10),
	@MATB nchar(10),		
	@NGAYTRANGBI date
AS
Begin
begin tran
if(@NGAYTRANGBI='')
begin
raiserror('ngày trang bị không được để trống!', 16, 1)
rollback
return
end
   Update TRANGBI
   set  MATB=@MATB,MAPHONG=@MAPHONG,NGAYTRANGBI=@NGAYTRANGBI
   where MAPHONG=@MAPHONG and MATB=@MATB
End
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-- Xóa trang bị

CREATE PROCEDURE sp_xoaTrangBi
@MaPhong nchar(10),
@MaTB nchar(10)
as
begin tran
delete from TRANGBI
where MATB= @MaTB and MAPHONG=@MaPhong
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran



-------DICHVU-------

--Thêm dịch vụ


CREATE PROCEDURE sp_themDichVu
    @MADV nchar(10),
	@TENDV nvarchar(10),		
	@GIADV float
as
begin tran
if(@MADV is null)
begin
raiserror('Mã dịch vụ không được để trống', 16, 1)
rollback
return
end
if(@TENDV ='')
begin
raiserror('Tên dịch vụ không được để trống', 16, 1)
rollback
return
end
if(@GIADV ='')
begin
raiserror('Phải nhập giá DV', 16, 1)
rollback
return
end
if(@MADV in (select MADV from DICHVU))
begin
raiserror ('Mã dịch vụ  đã bị trùng! Vui lòng nhập lại.',16,1)
rollback
return
end
insert into DICHVU values ( @MADV,@TENDV,@GIADV)
if(@@ERROR <>0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran


-- Sửa dịch vụ

CREATE PROCEDURE  sp_CapNhatDichVu
    @MADV nchar(10),
	@TENDV nvarchar(10),		
	@GIADV float
AS
Begin
begin tran
if(@GIADV='')
begin
raiserror('giá dv không được để trống!', 16, 1)
rollback
return
end
   Update DICHVU
   set  MADV=@MADV,TENDV=@TENDV,GIADV=@GIADV
   where MADV=@MADV
End
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-- Xóa dịch vụ

CREATE PROCEDURE sp_xoaDichVu
@MaDV nchar(10)
as
begin tran
delete from DICHVU
where MADV= @MaDV
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

-------DANGKY_DV-------
-- Chỉnh sửa đăng ký dịch vụ
CREATE PROCEDURE  sp_CapNhatDangKyDV
    @MADV nchar(10),
	@MAPDK nchar(10),		
	@NGAYBATDAU date,
	@NGAYKETHUC date
AS
Begin
begin tran
if(@NGAYBATDAU='')
begin
raiserror('ngày bắt đầu không được để trống!', 16, 1)
rollback
return
end
   Update DANGKY_DV
   set  MADV=@MADV,MAPDK=@MAPDK,NGAYBATDAU=@NGAYBATDAU,NGAYKETHUC=@NGAYKETHUC
   where MADV=@MADV and MAPDK=@MAPDK
End
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran
-- Thêm đăng ký dịch vụ
go
CREATE PROCEDURE sp_themDangKyDV
    @MADV nchar(10),
	@MAPDK nchar(10),		
	@NGAYBATDAU date,
	@NGAYKETHUC date
as
begin tran
if(@MADV is null)
begin
raiserror('Mã dịch vụ không được để trống', 16, 1)
rollback
return
end
if(@MAPDK ='')
begin
raiserror('mã pdk không được để trống', 16, 1)
rollback
return
end
if(@NGAYBATDAU ='')
begin
raiserror('Phải nhập ngày đăng ký', 16, 1)
rollback
return
end
insert into DANGKY_DV values ( @MADV,@MAPDK,@NGAYBATDAU,@NGAYKETHUC)
if(@@ERROR <>0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran
--Xóa đăng ký dịch vụ
go
CREATE PROCEDURE sp_xoaDangKyDV
@MaDV nchar(10),
@MaPDK nchar(10)
as
begin tran
delete from DANGKY_DV
where MADV= @MaDV and MAPDK=@MaPDK
if(@@ERROR <> 0)
begin
raiserror('Error', 16,1)
rollback
return
end
commit tran

----------TAIKHOAN----------

-- Thêm tài khoản login
create procedure sp_addTaiKhoan
@username nchar(10),
@pass nvarchar(25)
as
begin
	declare @SqlStringCreateLogin nvarchar(max)
	set @SqlStringCreateLogin='create LOGIN ['+@username+'] with password='''+@pass+''''+
	', DEFAULT_DATABASE=[QuanLyPhongTro],DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=ON,CHECK_POLICY=ON;'
	exec(@SQLStringCreateLogin)

	declare @SQLStringCreateUser nvarchar(max)
	set @SQLStringCreateUser = 'CREATE USER [' + @username + '] FOR LOGIN [' + @username+']'
	exec(@SQLStringCreateUser)


	if (@@ERROR <> 0)
	begin
	  RAISERROR(N'Có lỗi xảy ra khi tạo tài khoản', 16, 1)
	  rollback transaction
	  return
	end
end

-- Thêm tài khoản
create proc sp_addAccount
@MaKH nchar(10),
@Pass nchar(10)
as
begin
	insert into ACCOUNTS values(@MaKH,@Pass,'USERKH');
	execute sp_addrolemember 'USERKH',@MaKH
end


-- Xóa tài khoản login
create proc sp_deleteTaiKhoan(
@MaKH varchar(10))
as begin
	declare @DropLogin varchar(MAX)
	declare @DropUser varchar(MAX)
	SET @DropLogin = 'DROP LOGIN '+@MaKH
	SET @DropUser = 'DROP USER '+@MaKH
	DELETE dbo.KHACHHANG where MAKH=@MaKH
	DELETE dbo.PHIEUDANGKY where MAKH=@MaKH
	DELETE dbo.ACCOUNTS WHERE Username = @MaKH
	
	EXEC(@DropLogin)
	EXEC(@DropUser)
end
-- Xóa tài khoản
create proc sp_deleteAccount
@MaKH nchar(10)
as
begin
	DELETE dbo.ACCOUNTS WHERE Username = @MaKH
end
-----cap nhat quyen-------
use QuanLyPhongTro
go 
Create proc sp_capNhatQuyen(@MaROLE nchar(10),@user nchar(10))
as
  begin
      update ACCOUNTS set MaQ=@MaROLE where Username=@user
      execute sp_addrolemember @MaROLE,@user;
  end
go

execute sp_capNhatQuyen 'USERKH','KH16'
drop proc sp_capNhatQuyen
  
-- Thay đổi mật khẩu-----
go
create proc sp_ChangePassWord
@Username nvarchar(5),
@Passwordmoi nvarchar(5),
@Passwordcu nvarchar(5)
as
begin
	update ACCOUNTS set ACCOUNTS.Pwd = @Passwordmoi where
	Username = @Username
	execute sp_password @old =@Passwordcu, @new
	=@Passwordmoi, @loginame = @Username
	execute sp_addrolemember 'USERKH',@Username


	if (@@ERROR<>0)
	begin
		RAISERROR(N' Có lỗi xảy ra khi đổi mật khẩu', 16, 1)
		rollback tran
		return
	end
end

-------------Check Login-------------
create procedure  sp_CheckLogin
(
@Username nvarchar(20),
@Password nvarchar(20)
)
as
	begin
			if exists (select *from Accounts where Username=@Username
			and Accounts.Pwd=@Password)
			begin
				select *from Accounts where Username=@Username
				and Accounts.Pwd=@Password
			end	
			else
			begin
				RAISERROR(N' Có lỗi xảy ra ', 16, 1)
				rollback tran
				return	
			end	
	end