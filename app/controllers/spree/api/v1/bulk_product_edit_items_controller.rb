module Spree
  module Api
    module V1
      class BulkProductEditItemsController < Spree::Api::BaseController

        def products_for_selection

          case params[:select_by]
            when 'taxon'
              @new_products = products_by_taxon
            when 'sku'
             @new_products = products_by_sku
          end

          @selected_products = selected_products
          filter_new_products

          @products = (@new_products + @selected_products).sort! { |x, y| x['name'] <=> y['name'] }
          render json: { products: @products }
        end

        private

        def products_by_taxon
          taxon_ids = params[:identifiers]
          products = []
          Spree::Taxon.where(id: taxon_ids).each do |taxon|
            base_taxon_products = taxon.products.includes(master: [:images])
            children_taxon_products = taxon.children.includes(products: [master: [:images]]).map(&:products).flatten.compact.uniq
            products += (base_taxon_products + children_taxon_products).uniq
          end
          format_for_list products, false
        end

        def products_by_sku
          skus = params[:identifiers]
          products = Spree::Product.includes(master: [:images]).where(id: Spree::Variant.where(sku: skus).pluck(:product_id))
          format_for_list products, false
        end

        def selected_products
          bulk_product_edit_id = params[:bulk_product_edit_id]
          product_ids = Spree::BulkProductEditItem.where(bulk_product_edit_id: bulk_product_edit_id).pluck(:product_id)
          products = Spree::Product.includes(master: [:images]).where(id: product_ids)
          format_for_list products, true
        end

        def format_for_list products, selected
          out = []
          products.each do |p|
            attrs = p.attributes
            attrs[:sku] = p.master.sku
            attrs[:selected] = selected
            attrs[:thumbnail] = "https://dywimages.s3.amazonaws.com/spree/images/#{p.master.images[0].id}/mini/#{p.master.images[0].attachment_file_name}?#{rand(999999999)}"
            out << attrs
          end
          out
        end

        def filter_new_products
          @new_products.reject! { |p| in_selected? p }
        end

        def in_selected? product
          @selected_products.index { |s| s['id'] == product['id'] }
        end

      end
    end
  end
end
