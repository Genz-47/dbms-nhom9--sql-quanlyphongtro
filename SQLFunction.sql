use QuanLyPhongTro
-------------------------FUCTION--------------------------------
--create function tinhtongtien 
GO
alter function [dbo].[TONGTIEN] (
@MaPTT nchar(10)
)
returns FLOAT
as
begin
  declare @sum float
  declare @sothang int
  declare @giap float
  declare @giatb float
  declare @giadv float
  set @sothang=(Select SOTHANG from PHIEUTHANHTOAN where MAPTT=@MaPTT)
  set @giap=(select GIAPHONG from PHONGTRO,PHIEUDANGKY,PHIEUTHANHTOAN 
  where PHONGTRO.MAPHONG=PHIEUDANGKY.SOPHONG and PHIEUDANGKY.MAPDK=PHIEUTHANHTOAN.MAPDK and PHIEUTHANHTOAN.MAPTT=@MaPTT)
  set @giadv=(select sum(GIADV) from DICHVU,DANGKY_DV,PHIEUTHANHTOAN 
  where DICHVU.MADV=DANGKY_DV.MADV and DANGKY_DV.MAPDK=PHIEUTHANHTOAN.MAPDK and PHIEUTHANHTOAN.MAPTT=@MaPTT)
  set @giatb=(select SUM(GIATB) from THIETBI,PHIEUDANGKY,PHIEUTHANHTOAN 
  where THIETBI.MATB=PHIEUDANGKY.MATB and PHIEUDANGKY.MAPDK=PHIEUTHANHTOAN.MAPDK and PHIEUTHANHTOAN.MAPTT=@MaPTT)
  set @sum=(@giap+@giadv)*@sothang+@giatb
  return @sum
end
GO

select dbo.TONGTIEN('PTT04')

-----tim khach hang theo maKH
go
CREATE function timKH(@MaKH nchar(10))
returns table
as return
(
  select *
  from KHACHHANG
  where MAKH=@MaKH
)
----------tim theo so luong nguoi cua phong----
go
Create function TimPhong(@SLnguoi int)
returns table
as return 
(
   select *
   from PHONGTRO
   where SOLUONGNGUOI=@SLnguoi
)
--------------thong ke những Phiếu thanh toán có tổng tiền lớn hơn @
go
Create function TKHoaDon(@tongtien float)
returns table
as return 
(
   select *
   from PHIEUTHANHTOAN
   where TONGTIEN > @tongtien
)



----------------tinh tổng doanh thu trong tháng @ của nhà trọ-----
go
Create function Tinhtongthang(@thang int)
returns float
as 
begin
   declare @kq float
   select @kq=sum(TONGTIEN)
   from PHIEUTHANHTOAN
   where month(NGAYTT)=@thang
   group by MAPTT

   return @kq
end
----lietj ke nhung khach hang theo thang

go
create function sp_Thongkhthang9(@thang int)
returns table
as return
(
select *
from KHACHHANG
where MONTH(NGAYSINH)=@thang
)

---------------Laymatkhau-------------
go
CREATE function [dbo].[layMatKhau](@ID nchar(10))
returns nvarchar(50)
as
begin
declare @kq nvarchar(50)
select @kq = TaiKhoan.PassWord
from TaiKhoan
where TaiKhoan.ID = @ID
return @kq
end

-------------chọn những phòng trọ trang bị giá <200000 hoặc không có----------
go
Create function PTlow()
returns table
as return 
(
    select * from PHONGTRO
	where MAPHONG not in (select MAPHONG from TRANGBI) or GIAPHONG <2000000
)

