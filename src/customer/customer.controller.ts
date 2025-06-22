import { Controller, Get, Post, Body, Param, Delete } from '@nestjs/common';
import { ApiBody, ApiTags } from '@nestjs/swagger';
import { Customer } from './customer.entity';
import { CustomerService } from 'src/customer/customer.service';

import { ApiProperty } from '@nestjs/swagger';

export class CreateCustomerDto {
  @ApiProperty({ example: 'Juan Pérez', description: 'Nombre del cliente' })
  name: string;

  @ApiProperty({ example: '+34123456789', description: 'Teléfono del cliente' })
  phone: string;
}

@ApiTags('customers')
@Controller('customers')
export class CustomerController {
  constructor(private readonly customersService: CustomerService) {}

  @Get()
  findAll(): Promise<Customer[]> {
    return this.customersService.findAll();
  }

  @Post()
  @ApiBody({ type: CreateCustomerDto })
  create(@Body() customerData: CreateCustomerDto): Promise<Customer> {
    return this.customersService.create(customerData);
  }

  @Get(':id')
  findOne(@Param('id') id: string): Promise<Customer> {
    return this.customersService.findOne(Number(id));
  }

  @Delete(':id')
  async remove(@Param('id') id: string): Promise<{ message: string }> {
    await this.customersService.remove(Number(id));
    return { message: `Customer whit id ${id} removed` };
  }
}
