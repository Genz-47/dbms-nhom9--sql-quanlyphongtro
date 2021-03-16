-----------------------------Trigger-----------------------------


--Định dạng hiện trạng phòng khi có người đăng ký ở phòng.

Create trigger hientrangphong on PHIEUDANGKY
for insert,update
as 
begin
   declare @maphong nchar(20)
   select @maphong=ne.SOPHONG
   from inserted as ne
   if((select SOLUONGNGUOI from dbo.PHONGTRO where MAPHONG=@maphong)=0)
   begin
   update PHONGTRO
   set HIENTRANGPHONG='true'
   where PHONGTRO.MAPHONG=@maphong
   end
   else
   begin
   update PHONGTRO
   set SOLUONGNGUOI=SOLUONGNGUOI+1
   where PHONGTRO.MAPHONG=@maphong
   end
end
go
--Định dạng lại các giấy tờ liên quan khi khách rời khỏi phòng.
Create trigger khachroidi on KHACHHANG
instead of  delete
as 
begin
   declare @maKH nchar(20)
   select @maKH=ne.MAKH
   from deleted as ne
   delete HOADON
   where HOADON.MAPTT=(select MAPTT from PHIEUDANGKY,PHIEUTHANHTOAN where PHIEUDANGKY.MAPDK=PHIEUTHANHTOAN.MAPDK and PHIEUDANGKY.MAKH=@maKH)

   delete PHIEUTHANHTOAN
   where PHIEUTHANHTOAN.MAPDK=(select MAPDK from PHIEUDANGKY where PHIEUDANGKY.MAKH=@maKH)  
   
   delete DANGKY_DV
   where DANGKY_DV.MAPDK=(select MAPDK from PHIEUDANGKY where PHIEUDANGKY.MAKH=@maKH)

   delete PHIEUDANGKY
   where PHIEUDANGKY.MAKH=@maKH
   delete KHACHHANG
   where KHACHHANG.MAKH=@maKH
end

--Định dạng lại các phòng khi khách rời đi hết.
Create trigger hientrangphong2 on PHIEUDANGKY
for delete
as 
begin
   declare @maphong nchar(20)
   select @maphong=ne.SOPHONG
   from deleted as ne

   if((select SOLUONGNGUOI from dbo.PHONGTRO where MAPHONG=@maphong)=0)
   begin
   update PHONGTRO
   set HIENTRANGPHONG='false'
   where PHONGTRO.MAPHONG=@maphong
   end
end
-- Không được đăng ký 2 dịch vụ trùng nhau.
Create trigger test on DANGKY_DV
instead of insert
as 
begin
    if EXISTS(select *from inserted 
	where (inserted.MADV in (select MADV from DANGKY_DV) and inserted.MAPDK in (select MAPDK from DANGKY_DV))
	)
	begin
	  PRINT N'Không được sử dụng trùng loại dịc vụ'
	  ROLLBACK transaction
	end
	ELSE
BEGIN
DECLARE @MADV nchar(20)
DECLARE @MAPDK nchar(20)
DECLARE @Ngbd date
DECLARE @Ngkt date
set @MADV=(select MADV from inserted)
set @MAPDK=(select MAPDK from inserted)
set @Ngbd=(select NGAYBATDAU from inserted)
set @Ngkt=(select NGAYKETHUC from inserted)
INSERT INTO DANGKY_DV(MADV, MAPDK,NGAYBATDAU,NGAYKETHUC) VALUES(@MADV, @MAPDK,@Ngbd,@Ngkt)
END
end

--Ngày lập hóa đơn lớn hơn ngày thuê.
Create trigger ngaytrathue on HOADON
for Update,insert 
as
  IF UPDATE(NGAYLAPHD) 
    BEGIN
    DECLARE @NGHD DATE, @NGTHUE date
    SET @NGHD=(SELECT NGAYLAPHD FROM INSERTED)
    SET @NGTHUE=(SELECT NGAYTHUE FROM PHIEUDANGKY
	where MAPDK=(select MAPDK from PHIEUTHANHTOAN where MAPTT=(select MAPTT from inserted)))
    IF(@NGHD>@NGTHUE)
        BEGIN
        PRINT 'NGHD PHAI LON HON NGTHUE'
        ROLLBACK TRAN -- Câu lệnh quay lui khi thực hiện biến cố không thành công
        END
	END
-- Ngày lập hóa đơn phải lớn hơn ngày thanh toán.
Create trigger ktHoadon on HOADON
for Update,insert 
as
  IF UPDATE(NGAYLAPHD) 
    BEGIN
    DECLARE @NGHD DATE, @NGTT date
    SET @NGHD=(SELECT NGAYLAPHD FROM INSERTED)
    SET @NGTT=(SELECT NGAYTT FROM PHIEUTHANHTOAN A,inserted B where A.MAPTT=B.MAPTT)
    IF(@NGHD>@NGTT)
        BEGIN
        PRINT 'NGHD PHAI LON HON NGTHUE'
        ROLLBACK TRAN -- Câu lệnh quay lui khi thực hiện biến cố không thành công
        END
        END
--Mỗi phòng chỉ được trang bị tối đa 2 thiết bị.
Create trigger test2tb on TRANGBI
instead of insert
as 
begin
    declare @MAPHONG nchar(20);
	SET @MAPHONG=(SELECT MAPHONG FROM INSERTED)
    if((Select COUNT(MATB) from TRANGBI where TRANGBI.MAPHONG=@MAPHONG group by TRANGBI.MAPHONG)>=2)
	begin
	  PRINT N'phong nay da trang bi 2 thiet bi'
	  ROLLBACK transaction
	end
	ELSE
BEGIN
declare @MATB nchar(20);
declare @NGtb nchar(20);
set @MATB=(select MATB from inserted)
set @MAPHONG=(select MAPHONG from inserted)
set @NGtb=(select NGAYTRANGBI from inserted)
INSERT INTO TRANGBI(MATB,MAPHONG,NGAYTRANGBI) VALUES(@MATB, @MAPHONG,@NGtb)
END
end

delete TRANGBI where TRANGBI.MATB='TB02' and MAPHONG='PT05'
insert into TRANGBI values ('PT05','TB01','')

--Tổng tiền phải trả = trả trước + trả sau
Create trigger kttongtien on PHIEUDANGKY
instead of update
as 
BEGIN
declare @mapdk nchar(20);
declare @tratruoc float;
declare @trasau float;
set @mapdk=(select MAPDK from inserted)
set @tratruoc=(select TRATRUOC from inserted)
set @trasau=(select TRASAU from inserted)

if((@tratruoc+@trasau)=(select TONGTIEN from PHIEUTHANHTOAN where PHIEUTHANHTOAN.MAPDK='PDK11'))
begin
   update PHIEUDANGKY
   set TRATRUOC=@tratruoc,TRASAU=@trasau
   where PHIEUDANGKY.MAPDK=@mapdk
end
else 
begin
 PRINT N'Nhap Loi tien khong dung'
	 ROLLBACK transaction
end
END

--Tự động tính lại tổng tiền khi thay đổi giá phòng.
Create trigger tinhlaitongtien on PHONGTRO
for update
as 
BEGIN
  declare @maphong nchar(20); 
  declare @giacu float;
  declare @giamoi float;
  set @maphong=(select MAPHONG from inserted)
  set @giacu=(select GIAPHONG from deleted)
  set @giamoi=(select GIAPHONG from inserted)

  update PHIEUTHANHTOAN
  set TONGTIEN=TONGTIEN+(@giamoi-@giacu)
  where PHIEUTHANHTOAN.MAPDK in (select MAPDK from PHIEUDANGKY where PHIEUDANGKY.SOPHONG=@maphong)
END

update PHONGTRO set GIAPHONG=2500000 where MAPHONG='PT05'

-- Thêm khách hàng không được trùng số CMND.
create trigger insertCMNDKhachHang
on KHACHHANG
for insert
as

	begin
		declare @SOCMND int
		declare @cmnd int
		declare @so int = 1
		declare @tongSo int = (select count(*) from KHACHHANG)
		set @SOCMND = (select SOCMND from inserted)
		while(@so<=@tongSo)
		begin
			select @cmnd =  SOCMND from KHACHHANG where MAKH='KH0'+convert(nchar(2),@so)
			if(@cmnd = @SOCMND)
				BEGIN
					print 'CMND khong duoc trung nhau'
					rollback transaction;
				END
			set @so = @so +1;
		end
	end
go
------------------CAPNHATQUYEN------------------

create trigger capnhatquyen on ACCOUNTS
instead of update
as
begin
     declare @maQ nchar(10)
	 declare @user nchar(10)
	 declare @pwd nchar(10)
	 set @maQ=(select MaQ from deleted)
	 set @user=(select Username from deleted)
	 EXEC sp_droprolemember @maQ, @user

	 set @maQ=(select MaQ from inserted)
	 set @user=(select Username from inserted)
	 set @pwd =(select Pwd from inserted)
	 update ACCOUNTS set MaQ=@maQ,Username=@user,Pwd=@pwd where Username=@user

end
go